#!/usr/bin/env bash
# claude-config 설치 스크립트
# repo 의 claude/ payload 를 ~/.claude 로 복사하고,
# profiles/<프로필>/infra_rule.md 를 rules/ 에 얹는다.
# 기존 파일은 ~/.claude/backup_<timestamp>/ 에 백업 후 덮어쓴다.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$REPO_DIR/claude"
PROFILES="$REPO_DIR/profiles"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$CLAUDE_DIR/backup_$STAMP"

# --- 머신 프로필 결정 -------------------------------------------------
# 우선순위: PROFILE 환경변수 > 기록된 이전 선택 > OS 자동 감지
detect_profile() {
    case "$(uname -s)" in
        Darwin) echo "mac" ;;
        Linux)  echo "server" ;;
        *)      echo "" ;;
    esac
}
PROFILE="${PROFILE:-$(cat "$CLAUDE_DIR/.claude-config-profile" 2>/dev/null || detect_profile)}"

if [ -z "$PROFILE" ] || [ ! -d "$PROFILES/$PROFILE" ]; then
    echo "ERROR: 프로필을 정할 수 없음 (PROFILE='$PROFILE')"
    echo "  사용 가능: $(ls "$PROFILES" 2>/dev/null | tr '\n' ' ')"
    echo "  예: PROFILE=mac ./install.sh"
    exit 1
fi

[ -d "$PAYLOAD" ] || { echo "ERROR: $PAYLOAD 없음"; exit 1; }
mkdir -p "$CLAUDE_DIR"
echo "[profile] $PROFILE  →  $CLAUDE_DIR"

backup() {
    local target="$1"
    if [ -e "$CLAUDE_DIR/$target" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$target")"
        cp -r "$CLAUDE_DIR/$target" "$BACKUP_DIR/$target"
    fi
}

# 1) 전역 CLAUDE.md / rules / rules_archive / templates — 통째로 교체
for item in CLAUDE.md rules rules_archive templates; do
    backup "$item"
    rm -rf "${CLAUDE_DIR:?}/$item"
    cp -r "$PAYLOAD/$item" "$CLAUDE_DIR/$item"
    echo "[install] $item"
done

# 2) 머신별 인프라 규칙 — rules/ 를 교체한 뒤에 얹어야 한다
cp "$PROFILES/$PROFILE/infra_rule.md" "$CLAUDE_DIR/rules/infra_rule.md"
printf '%s\n' "$PROFILE" > "$CLAUDE_DIR/.claude-config-profile"
echo "[install] rules/infra_rule.md ($PROFILE)"

# 3) settings.json — base + 프로필 patch + 기존 로컬을 합집합 병합
#    덮어쓰지 않는 이유: "항상 허용"으로 쌓인 로컬 권한이 재설치로 사라지면 안 된다
backup "settings.json"
python3 "$REPO_DIR/scripts/merge_settings.py" \
    "$PAYLOAD/settings.base.json" \
    "$PROFILES/$PROFILE/settings.patch.json" \
    "$CLAUDE_DIR/settings.json" \
    "$CLAUDE_DIR/settings.json.tmp"
mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
echo "[install] settings.json (base + $PROFILE + 로컬 병합)"

# 4) 스킬 — 이 repo 가 아니라 kitemo-plugins marketplace 가 제공한다.
#    claude CLI 가 없거나 SKIP_PLUGINS=1 이면 안내만 하고 넘어간다.
PLUGIN_MARKETPLACE="${PLUGIN_MARKETPLACE:-kite-mo/kitemo-plugins}"
PLUGIN_NAME="${PLUGIN_NAME:-personal-common}"

install_plugins() {
    if [ -n "${SKIP_PLUGINS:-}" ]; then
        echo "[skip]    플러그인 설치 건너뜀 (SKIP_PLUGINS)"
        return 0
    fi
    if ! command -v claude >/dev/null 2>&1; then
        echo "[skip]    claude CLI 없음 — 스킬은 설치되지 않았습니다."
        echo "          설치 후 아래를 직접 실행하세요:"
        echo "            claude plugin marketplace add $PLUGIN_MARKETPLACE"
        echo "            claude plugin install $PLUGIN_NAME@kitemo-plugins"
        return 0
    fi
    # marketplace add 는 이미 등록돼 있으면 실패하므로 update 로 대체한다
    if claude plugin marketplace list 2>/dev/null | grep -q 'kitemo-plugins'; then
        claude plugin marketplace update kitemo-plugins >/dev/null 2>&1 \
            && echo "[plugin]  marketplace 갱신" \
            || echo "[warn]    marketplace 갱신 실패 — 수동 확인 필요"
    else
        claude plugin marketplace add "$PLUGIN_MARKETPLACE" >/dev/null 2>&1 \
            && echo "[plugin]  marketplace 등록: $PLUGIN_MARKETPLACE" \
            || { echo "[warn]    marketplace 등록 실패 — 수동 확인 필요"; return 0; }
    fi
    if claude plugin list 2>/dev/null | grep -q "$PLUGIN_NAME"; then
        claude plugin update "$PLUGIN_NAME" >/dev/null 2>&1 \
            && echo "[plugin]  $PLUGIN_NAME 갱신 (적용은 다음 세션부터)" \
            || echo "[plugin]  $PLUGIN_NAME 이미 최신"
    else
        claude plugin install "$PLUGIN_NAME@kitemo-plugins" >/dev/null 2>&1 \
            && echo "[plugin]  $PLUGIN_NAME 설치" \
            || echo "[warn]    $PLUGIN_NAME 설치 실패 — 수동 확인 필요"
    fi
}
install_plugins

# 5) 마이그레이션 — 예전 버전은 스킬을 ~/.claude/skills/ 로 복사했다.
#    그대로 두면 플러그인과 같은 이름의 스킬이 두 벌 로드된다.
#    백업만 남기고 치운다 (플러그인이 이제 정본).
LEGACY_SKILLS="$CLAUDE_DIR/skills"
if [ -d "$LEGACY_SKILLS" ] && [ -n "$(ls -A "$LEGACY_SKILLS" 2>/dev/null)" ]; then
    backup "skills"
    rm -rf "${LEGACY_SKILLS:?}"
    echo "[migrate] 구버전 ~/.claude/skills 제거 (플러그인과 중복) — 백업됨"
fi

if [ -d "$BACKUP_DIR" ]; then
    echo "[backup]  기존 파일 백업 → $BACKUP_DIR"
fi

cat << EOF

✅ 설치 완료 (프로필: $PROFILE)
   머신 종속 값은 rules/infra_rule.md 에만 있습니다.
   틀린 내용이 있으면 profiles/$PROFILE/infra_rule.md 를 고치세요.
   새 머신이라면: PROFILE=<이름> ./install.sh  (profiles/ 에 디렉토리 추가)
EOF
