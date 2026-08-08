# 인프라 — GPU 서버 (profile: server)

이 파일은 **머신 종속 사실**만 담는다. 소통 원칙·도메인 기본값은
`user_context_rule.md` 담당 (중복 금지).

> 📝 아직 채워지지 않은 템플릿이다. GPU 서버를 구축하면 아래 `<...>`
> 자리를 실제 값으로 바꾸고 `PROFILE=server ./install.sh` 로 설치한다.

## 하드웨어

- Linux 서버, GPU `<개수·용량>`
- 실행 전 `nvidia-smi` 로 점유 확인 후 빈 GPU 할당
- 코드 내에서 device 를 직접 지정하는 프로젝트는 `CUDA_VISIBLE_DEVICES`
  를 쓰지 않는다 — 프로젝트 관례를 먼저 확인할 것

## Python 환경

- 프로젝트별 uv `.venv` 우선
- 프로젝트 venv 에 jupyter 도구(nbformat/nbconvert)가 없으면
  `<폴백 venv 경로>` 사용

## Claude 설정 경로

- 설정 실체: `~/.claude/`
- memory: `~/.claude/projects/<작업디렉토리 슬러그>/memory/MEMORY.md`
  슬러그는 홈이 아니라 **세션의 작업 디렉토리**에서 파생된다 (`/` → `-`)

## 실험 실행

- 이 머신은 학습·실험 실행 환경이다. `experiment-runner`,
  `experiment-notebook` 스킬의 GPU 절차를 그대로 적용한다.
