---
name: experiment-runner
description: 장시간 GPU 실험을 재현 가능하게 실행·관리. 사용자가 실험 실행, 학습 돌리기, nohup 실행, baseline 비교, seed 실험, "지금 어느 단계 실행중인지" 상태 확인을 요청할 때 사용. 재현성 원칙(seed·환경·저장 규칙)과 nohup 큐 러너 패턴을 강제한다.
---

# Experiment Runner

장시간 ML 실험을 재현 가능하고 추적 가능하게 실행한다. 과거 세션에서
반복적으로 확립된 원칙(seed 고정, .venv 사용, nohup + 로그, progress
트래킹, 논문 세팅 default)을 기본값으로 적용한다.

## 사용 시점

- 학습/실험 스크립트 실행 요청 ("돌려줘", "실험 시작하자")
- nohup 백그라운드 실행 요청
- 실행 중 실험의 상태/로그 확인 요청
- multi-seed, baseline 비교 등 실험 계획 수립

## 핵심 원칙 (항상 적용)

1. **실행 전 방법 먼저 설명** — 사용자가 명시적으로 실행을 지시하기
   전에는 명령어와 계획을 먼저 보여준다.
2. **재현성 기본값** — seed 고정(프로젝트 관례 확인, 기본 42),
   deterministic 설정 여부 명시, config 를 결과와 함께 저장.
   Default 는 항상 기준(논문/운영) 세팅 재현이고, 변형은 명시적
   플래그로만 활성화한다.
3. **환경 확인** — 프로젝트 `.venv/bin/python` 우선 사용. 다른 전역
   인터프리터(conda base 등)와 혼동 금지. GPU 절차는 `rules/infra_rule.md`
   를 먼저 확인한다 — GPU 가 있는 머신이면 실행 전 `nvidia-smi` 로 점유
   확인 후 빈 GPU 할당, **GPU 없는 머신이면 이 스킬로 학습을 돌리지 말고
   실험 서버에서 실행하도록 안내한다**.
4. **기준값 대조 게이트** — 재현 실험은 기존 기록된 수치와 대조하고,
   불일치 시 원인(환경 드리프트, seed, batch size 등 config 차이)을
   먼저 규명한 후 본 실험을 진행한다.
5. **config diff 확인** — 실행 전 batch size, epochs 등 핵심
   하이퍼파라미터가 기준 세팅과 일치하는지 확인한다 (과거 batch
   128→32 유입으로 게이트 무효화된 사례 있음).

## 장시간 실행 패턴 (nohup)

`references/nohup_patterns.md` 에 상세 패턴과 트러블슈팅이 있다.
요약:

```bash
# python -u 필수: 버퍼링 때문에 로그가 실시간으로 남지 않는 문제 방지
nohup .venv/bin/python -u script.py [args] \
    > logs/$(date +%y%m%d_%H%M%S)_<실험명>.log 2>&1 &
echo $!  # PID 기록
```

여러 실험은 개별 nohup 대신 **큐 러너** 스크립트로 순차 실행하고
`progress.json` 에 상태를 기록한다 (동시 실행으로 인한 GPU OOM 방지).

## 상태 확인

```bash
nvidia-smi                                        # GPU 점유
ps aux | grep -E "python.*run_" | grep -v grep     # 프로세스
tail -20 logs/<최신>.log                           # 로그
cat experiments/**/progress.json 2>/dev/null       # 큐 진행 상황
```

## 실험 계획 수립 시

새 실험 계획은 `~/.claude/templates/experiment_plan.md` 템플릿을
복사해 작성한다 (목적, 조건 매트릭스, seed, GPU 할당, 검증 게이트,
저장 경로 포함). 결과 저장 경로는 기존 결과와 분리된 실험 ID 폴더를
사용한다 (예: `experiments/<실험ID>/`).

## 연계

- 실험 **완료 후 결과 정리**(4단계 노트북)는 experiment-notebook 스킬 담당.
