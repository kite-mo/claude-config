---
name: usage-report
description: Claude Code 사용량을 팀 통일 포맷 CSV/Markdown 으로 리포트. 사용자가 사용량 확인, 요금 확인, ccusage, 월별 사용 리포트, 팀 사용량 정리를 요청할 때 사용.
---

# Usage Report

`ccusage` 출력을 팀에서 합의한 통일 포맷(월별 CSV)으로 변환한다.
팀에서 매달 사용 요금을 확인하므로 매번 포맷을 다시 정하지 않도록
스크립트로 고정한다.

## 사용 시점

- "이번 달 사용량 뽑아줘" / "사용 이력 CSV로"
- 팀 월별 요금 정리 요청

## 실행 방법

```bash
# 월별 리포트 (기본: 이번 달)
python3 scripts/usage_report.py

# 특정 월
python3 scripts/usage_report.py --month 2026-07

# 출력 위치 지정
python3 scripts/usage_report.py --output ~/usage_reports/
```

스크립트는 `npx ccusage --json` 을 호출해 다음 컬럼의 CSV 를 생성한다:

`month, user, model, input_tokens, output_tokens, cache_read_tokens,
cache_write_tokens, total_cost_usd`

## 출력 포맷 (팀 통일)

- 파일명: `claude_usage_<YYYY-MM>_<사용자명>.csv`
- 요약 Markdown 을 함께 출력: 총 비용, 모델별 비중, 전월 대비
- `ccusage` 미설치 시 `npx ccusage@latest` 로 대체 실행

## 주의사항

- ccusage 는 로컬 트랜스크립트 기반 추정치이므로 실제 청구액과 다를 수
  있음을 리포트 하단에 명시한다.
