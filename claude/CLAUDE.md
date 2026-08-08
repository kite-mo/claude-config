<!-- User customizations (migrated from previous CLAUDE.md) -->
# Claude Code Global Configuration

이 파일은 모든 프로젝트에 공통으로 적용되는 Claude Code 설정입니다.

세션 시작 시, 최초로 전달받는 system prompt 와 rules 디렉토리 기반 공통 system prompt 를 알려줍니다. 
그리고 사용 가능한 claude skill 항목들을 정리하여 사용자에게 알려줍니다.
또한 프로젝트 폴더에서 실행 시, 해당 프로젝트에서 처리되는 system prompt 에 대해서도 사용자에게 알려줍니다.

**claude skill 을 사용하게 되면, 해당 skill 을 사용하고 있다는 여부를 반드시 얘기합니다.**
**모든 작업 시 `~/.claude/rules/reasoning_principles.md` 의 통합 원리(Karpathy 4원칙 흡수)를 따르라. 단, 사소한 한 줄 수정·오타 등 trivial 작업은 판단에 맡긴다.**

## 📂 프로젝트 구조
- `~/.claude/rules/`: Claude 시스템 규칙 폴더 (매 세션 자동 로드 — 최소·무중복 유지)
  - `user_context_rule.md`: 사용자 컨텍스트 — 소통·협업 원칙 9개, 진행 프로젝트 (머신 무관)
  - `infra_rule.md`: **이 머신의 인프라 사실** — GPU 유무, Python 환경, 경로.
    머신마다 다르므로 claude-config repo 의 `profiles/<프로필>/` 에서 설치된다.
    GPU·경로가 걸린 판단은 반드시 이 파일을 먼저 확인한다
  - `reasoning_principles.md`: 통합 사고·작업 원리 7개 + 표준 흐름 (Karpathy 4원칙 흡수)
  - `python_coding_rule.md`: Python 코딩 표준
- `~/.claude/rules_archive/`: 흡수·폐기된 규칙 원본 보관 (자동 로드 안 됨)
- `~/.claude/templates/`: 작업 템플릿 (실험 계획, 리뷰 대응)
- **스킬은 이 repo 가 아니라 `kite-mo/kitemo-plugins` marketplace 의
  `personal-common` 플러그인이 제공한다** (상황별 온디맨드 로드).
  `claude plugin list` 로 설치 여부를 확인할 수 있다.
