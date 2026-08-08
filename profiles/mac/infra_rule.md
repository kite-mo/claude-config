# 인프라 — 맥북 로컬 (profile: mac)

이 파일은 **머신 종속 사실**만 담는다. 소통 원칙·도메인 기본값은
`user_context_rule.md` 담당 (중복 금지).

## 하드웨어

- macOS, Apple Silicon (arm64). **NVIDIA GPU 없음, `nvidia-smi` 없음**
- 학습·실험 실행 머신이 아니다. 무거운 실험이 필요하면 별도 GPU 서버를
  구축해 거기서 돌린다. 이 머신에서 `nvidia-smi`·`CUDA_VISIBLE_DEVICES`
  를 전제한 절차를 제안하지 말 것
- 여기서 하는 일: 코드 편집, 소규모 분석, 논문·문서 작업, 설정 관리

## Python 환경

- **uv 단일 체계. conda 없음** (제거됨 — `conda activate` 제안 금지)
- 인터프리터: `uv python` 관리. 현재 3.12, 3.13 (네이티브 arm64)
- 프로젝트별 `.venv` — `mkvenv [버전]` 으로 생성, 디렉토리 진입 시
  자동 활성화 (`.zshrc` 의 `_auto_venv`)
- 전역 CLI: `uv tool` (현재 ruff, ipython, jupyterlab). 1회성은 `uvx`
- jupyter 도구: 프로젝트 venv 에 nbformat/nbconvert 가 없으면
  `~/.local/share/uv/tools/jupyterlab/bin/python` 사용
- 즉석 실험용 공유 venv: `~/dev/sandbox/.venv` (`sb` 로 이동)

## 디렉토리

- 작업 루트는 `~/dev` — 규칙은 `~/dev/README.md` 가 기준
- `repos/{work,personal,oss}` = git 관리 대상, `sandbox/` = 실험(git 없음),
  `data/` = 대용량, `tools/` = 자작 스크립트, `archive/` = 보관
- git 커밋 신원은 `includeIf` 로 디렉토리마다 자동 분리
- 새 프로젝트·클론은 항상 `~/dev` 트리 안에 만든다

## Claude 설정 경로

- 설정 실체는 `~/dev/.claude-home/` 이고 `~/.claude` 는 여기로 걸린
  디렉토리 심볼릭 링크다. `~/.claude/...` 경로는 그대로 써도 된다
- 인증 파일 `~/.claude.json` 만 홈에 남아 있다 (앱이 통째로 덮어쓰는
  파일이라 단일 파일 링크는 끊어지기 때문)
- memory: `~/.claude/projects/<작업디렉토리 슬러그>/memory/MEMORY.md`
  슬러그는 홈이 아니라 **세션의 작업 디렉토리**에서 파생된다
  (`/` → `-`). 예: `~/dev` 에서 실행하면 `-Users-kitemo-dev`
