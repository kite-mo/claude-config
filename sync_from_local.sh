#!/usr/bin/env bash
# 역방향 동기화: 현재 머신의 ~/.claude 상태를 repo 로 가져온다.
# 로컬에서 rules/skills 를 수정한 뒤 커밋 전에 실행.
#
# 중요: rules/infra_rule.md 는 머신 종속이므로 공통 rules 가 아니라
#       profiles/<프로필>/ 로만 되돌린다. 다른 머신 프로필은 건드리지 않는다.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$REPO_DIR/claude"
PROFILES="$REPO_DIR/profiles"

PROFILE="${PROFILE:-$(cat "$CLAUDE_DIR/.claude-config-profile" 2>/dev/null || true)}"
if [ -z "$PROFILE" ] || [ ! -d "$PROFILES/$PROFILE" ]; then
    echo "ERROR: 프로필 불명 (PROFILE='$PROFILE')"
    echo "  install.sh 를 먼저 돌렸다면 $CLAUDE_DIR/.claude-config-profile 이 있어야 합니다."
    echo "  또는: PROFILE=mac ./sync_from_local.sh"
    exit 1
fi
echo "[profile] $PROFILE  ←  $CLAUDE_DIR"

# 1) 공통 payload
for item in CLAUDE.md rules rules_archive templates; do
    rm -rf "${PAYLOAD:?}/$item"
    cp -r "$CLAUDE_DIR/$item" "$PAYLOAD/$item"
    echo "[sync] $item"
done

# 2) 머신 종속 규칙은 공통에서 빼고 프로필로 보낸다
if [ -f "$PAYLOAD/rules/infra_rule.md" ]; then
    mv "$PAYLOAD/rules/infra_rule.md" "$PROFILES/$PROFILE/infra_rule.md"
    echo "[sync] profiles/$PROFILE/infra_rule.md  (공통 rules 에서 제외됨)"
else
    echo "[warn] $CLAUDE_DIR/rules/infra_rule.md 없음 — 프로필 갱신 건너뜀"
fi

# 3) 스킬은 이 repo 소관이 아니다. kitemo-plugins repo 에서 직접 수정한 뒤
#    `claude plugin marketplace update kitemo-plugins` 로 반영한다.

# 4) settings.json 은 자동으로 끌어올리지 않는다.
#    로컬에는 "항상 허용"으로 쌓인 1회용 승인이 섞여 있어 그대로 올리면
#    베이스라인이 오염된다. 차이만 보고하고 승격 여부는 사람이 판단한다.
echo
python3 "$REPO_DIR/scripts/merge_settings.py" \
    "$PAYLOAD/settings.base.json" \
    "$PROFILES/$PROFILE/settings.patch.json" \
    "$CLAUDE_DIR/settings.json" \
    /dev/null
echo "[settings] 위 항목 중 계속 쓸 것만 골라 직접 옮기세요:"
echo "           머신 무관 → claude/settings.base.json"
echo "           이 머신만 → profiles/$PROFILE/settings.patch.json"

echo
echo "✅ 동기화 완료. git diff 로 변경 확인 후 커밋하세요."
echo "   다른 머신 프로필(profiles/*)이 diff 에 뜨면 잘못된 것입니다."
