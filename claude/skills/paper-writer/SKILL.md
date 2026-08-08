---
name: paper-writer
description: ML/제조 도메인 학술 논문 작성 지원 — LaTeX 섹션·figure·캡션 작성, 리뷰어 대응, 설비 개략도 설계. 사용자가 논문 작성, LaTeX figure, 캡션, 섹션 초안, revision 대응, 실험 결과 표를 요청할 때 사용.
---

# Paper Writer

제조/반도체 이상탐지 도메인의 학술 논문(예: AEI, JMS 급 저널) 작성을
지원한다. 과거 논문 작업에서 확립된 스타일과 원칙을 기본값으로 적용한다.

## 사용 시점

- LaTeX figure/subfigure/표 + 캡션 작성
- 논문 섹션 초안 작성 또는 국문 초안 → 영문 변환
- 리뷰어 코멘트 대응 (revision response)
- 설비 개략도 등 논문용 다이어그램 설계

## 핵심 원칙

1. **독자 수준에 맞는 개념적 단순화** — 제조 시스템 저널 독자는 해당
   공정의 전문가가 아니다. 물리적 완벽함보다 **전달력**을 우선한다.
   단순화 결정과 그 근거를 명시한다.
2. **차트/figure 는 영문 전용** — 축, 범례, 라벨 모두 영문.
3. **캡션은 자기완결적으로** — 본문 없이 캡션만 읽어도 figure 를 이해할
   수 있게: 무엇을 보여주는지 + 색/스타일 의미 (예: "Blue: normal
   samples; Red: anomaly sample") + 핵심 해석 한 줄.
4. **수치는 출처와 함께** — 논문에 넣는 모든 수치는 생성한
   노트북/결과 파일 경로를 주석 또는 아카이브에 기록한다
   (revision 때 "이 수치 어디서 나왔지" 문제 방지).
5. **본문 서술 구조** — figure 분석 문단은
   "무엇을 보여주는가 → 정상 케이스 관찰 → 이상 케이스 관찰 →
   해석(메커니즘) → 주장과의 연결" 순서로 쓴다.

## LaTeX 패턴

자주 쓰는 figure 패턴은 `assets/latex_figure_patterns.tex` 에 있다:
- 세로 배치 subfigure (inter/intra 비교 등 2단 구성)
- 가로 배치 subfigure
- 결과 표 (booktabs)

elsarticle 계열은 `\begin{figure*}[pos=ht]` 형식을 사용한다.

## Revision 대응 절차

1. 리뷰어 코멘트를 분류 (실험 요구 / 서술 수정 / 단순 오탈자)
2. 우선순위: 실험이 필요한 항목 먼저 (시간 소요)
3. 실험 항목은 experiment-runner 스킬과 연계하고, 논문 세팅 재현을
   default 로 한다
4. Response letter 는 "코멘트 인용 → 답변 → 원고 변경 위치" 3단 구성

## 연계

- revision 대응의 **논리 설계와 검증 실험 연계**는 rebuttal-response
  스킬 담당. 이 스킬은 확정된 논리의 LaTeX 반영(섹션·figure·표) 담당.
