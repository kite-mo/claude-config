# claude-config

개인 Claude Code **환경**(전역 지시·규칙·템플릿·권한)을 어느 PC/서버에서든
동일하게 이식하기 위한 설정 repo.

**스킬은 여기 없다.** 스킬은 [kite-mo/kitemo-plugins](https://github.com/kite-mo/kitemo-plugins)
marketplace 의 `personal-common` 플러그인이 담당한다. 두 repo 는 역할이 다르다.

| | claude-config (여기) | kitemo-plugins |
|---|---|---|
| 담당 | 환경 — CLAUDE.md, rules, templates, 권한, 머신 프로필 | 재사용 스킬 |
| 이유 | 플러그인은 rules 나 전역 settings 를 실을 수 없다 | 버전 관리·`/plugin update` 가 된다 |
| 설치 | `./install.sh` | `install.sh` 가 대신 호출 |

## 설치

```bash
git clone https://github.com/kite-mo/claude-config.git && cd claude-config
./install.sh
```

- payload 를 `~/.claude` 로 복사하고, 이어서 **플러그인 marketplace 등록과
  설치까지 수행한다.** 새 머신에서 이 두 줄이면 끝난다.
- 기존 `~/.claude` 파일은 `~/.claude/backup_<timestamp>/` 에 백업된다.
- `CLAUDE.md`/`rules`/`rules_archive`/`templates` 는 통째로 교체한다.
- `settings.json` 은 교체가 아니라 **병합**한다 (아래 "권한 설정" 참고).
- 대화 기록·인증(`projects/`, `.claude.json`)은 건드리지 않는다.
- `claude` CLI 가 없으면 플러그인 단계는 건너뛰고 안내만 출력한다.
  `SKIP_PLUGINS=1 ./install.sh` 로 명시적으로 끌 수도 있다.

## 구조

```
claude/                        ← ~/.claude 로 복사되는 payload
├── CLAUDE.md                  # 전역 설정 (세션 시작 안내, 규칙 로드 지시)
├── settings.base.json         # 공통 권한 베이스라인 (머신 무관)
├── rules/                     # 매 세션 자동 로드 (최소·무중복 원칙)
│   ├── user_context_rule.md   #   사용자 컨텍스트 — 소통·협업 9원칙, 프로젝트 (머신 무관)
│   ├── reasoning_principles.md#   통합 사고·작업 원리 7개 + 표준 흐름 (Karpathy 흡수)
│   └── python_coding_rule.md  #   Python 코딩 표준
├── rules_archive/             # 흡수·폐기된 규칙 원본 (자동 로드 안 됨)
└── templates/
    ├── experiment_plan.md     # 실험 계획 템플릿
    └── revision_response.md   # 리뷰 대응 템플릿

profiles/                      ← 머신 종속 값. 설치 시 하나만 골라 얹힌다
├── server/
│   ├── infra_rule.md          #   GPU 서버 (GPU 0~3, /home/.../.venv)
│   └── settings.patch.json    #   서버 전용 권한 (nvidia-smi)
└── mac/
    ├── infra_rule.md          #   맥북 로컬 (GPU 없음, uv 단일 체계, ~/dev)
    └── settings.patch.json    #   맥북 전용 권한

scripts/merge_settings.py      ← settings 병합기 (base + patch + 로컬)
```

### 설계 원칙

- **rules 층은 최소·무중복**: 매 세션 로드되므로 원칙이 겹치거나 많으면
  주의가 희석된다. 파일당 단일 책임 — user_context(스타일·사실) /
  reasoning(사고·검증) / python(문법 표준).
- **절차는 스킬로**: 상황별 세부 절차는 rules 에 넣지 않고 스킬로 분리
  (트리거될 때만 로드). 스킬은 kitemo-plugins repo 가 갖는다.
- **환경과 스킬을 분리**: rules·settings 는 머신에 붙는 것이라 파일 복사로
  설치하고, 스킬은 재사용 단위라 플러그인으로 버전 관리한다. 한 repo 에
  섞으면 스킬만 업데이트하고 싶을 때 환경까지 건드리게 된다.

## 머신 프로필

머신마다 다른 값(GPU 유무, Python 환경, 경로)은 payload 에 섞지 않고
`profiles/<이름>/infra_rule.md` 한 파일에 모아둔다. 설치 시 이 머신에
맞는 것 하나만 `rules/infra_rule.md` 로 얹힌다.

```bash
./install.sh                 # OS 로 자동 감지 (Darwin→mac, Linux→server)
PROFILE=server ./install.sh  # 명시 지정
```

선택된 프로필은 `~/.claude/.claude-config-profile` 에 기록되어 이후
`install.sh`/`sync_from_local.sh` 가 같은 프로필을 유지한다.

**새 머신 추가:** `profiles/<이름>/infra_rule.md` 를 만들고
`PROFILE=<이름> ./install.sh`. 기존 프로필과 payload 는 건드리지 않는다.

> ⚠️ 스킬·템플릿에 머신 종속 값(GPU 명령, 절대 경로)을 다시 하드코딩하지 말 것.
> `rules/infra_rule.md` 를 참조하도록 쓴다. 그래야 한 머신의 수정이
> 다른 머신을 깨뜨리지 않는다.

## 권한 설정 (settings.json)

`settings.json` 은 **덮어쓰지 않고 병합**한다. Claude 가 "항상 허용"을
누를 때마다 직접 쓰는 파일이라, 덮어쓰면 재설치할 때마다 그동안 승인한
권한이 사라진다.

```
claude/settings.base.json  +  profiles/<프로필>/settings.patch.json  +  기존 로컬
                           ↓  합집합 (배열 union, 중복 제거)
                    ~/.claude/settings.json
```

`sync_from_local.sh` 는 **settings 를 repo 로 끌어올리지 않는다.** 로컬에는
1회용 승인(특정 URL, 특정 스크립트, 깨진 따옴표)이 섞이기 때문에 자동으로
올리면 베이스라인이 오염된다. 대신 repo 에 없는 로컬 항목을 목록으로 찍어주고,
계속 쓸 것만 사람이 골라 `settings.base.json`(머신 무관) 또는
`settings.patch.json`(그 머신만) 으로 옮긴다.

**베이스라인 원칙:** 조회 계열(git status/diff/log, ls, rg)과 uv·ruff 등
프로젝트 안에서만 작용하는 명령만 넣는다. `pip install` 은 넣지 않는다 —
시스템 Python 을 오염시키는 경로이고 uv 단일 체계와 어긋난다. 같은 편의는
`uv add`·`uv pip install` 이 프로젝트 `.venv` 안에서 제공한다.
임의 코드를 실행하는 `uv run` 도 의도적으로 제외했다 (매번 확인받는다).

## 관리 플로우

```bash
# 로컬 ~/.claude 에서 규칙/템플릿을 수정·검증한 뒤:
./sync_from_local.sh   # ~/.claude → repo (infra_rule.md 는 현재 프로필로만)
git diff               # 변경 확인 — 다른 머신의 profiles/* 가 뜨면 잘못된 것
git add -A && git commit
git push

# 다른 서버에서:
git pull && ./install.sh
```

## 참고

- 이 repo 는 **개인 작업 방식**(사고 원리·연구 워크플로우) 전용이다.
  조직 공용 스킬을 쓰게 되면 그건 별도 plugin marketplace 로 관리하고
  여기에 섞지 않는다.
- 스킬을 고치려면 kitemo-plugins repo 에서 작업한 뒤
  `claude plugin marketplace update kitemo-plugins` 로 반영한다.
  이 repo 의 `sync_from_local.sh` 는 스킬을 다루지 않는다.
