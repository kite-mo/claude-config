#!/usr/bin/env python3
"""Claude Code 사용량을 팀 통일 포맷 CSV/Markdown 으로 변환합니다.

`npx ccusage --json` 출력을 파싱하여 월별 CSV 와 요약 Markdown 을
생성합니다.

Usage:
    python3 usage_report.py [--month YYYY-MM] [--output DIR]
"""

import argparse
import csv
import getpass
import json
import subprocess
import sys
from datetime import date
from pathlib import Path
from typing import Dict, List, Optional

CSV_COLUMNS = [
    "month",
    "user",
    "model",
    "input_tokens",
    "output_tokens",
    "cache_read_tokens",
    "cache_write_tokens",
    "total_cost_usd",
]


def run_ccusage() -> dict:
    """ccusage 를 실행하고 JSON 결과를 반환합니다.

    Returns:
        ccusage 의 daily breakdown JSON 딕셔너리

    Raises:
        RuntimeError: ccusage 실행 실패 시
    """
    for cmd in (["npx", "ccusage", "--json", "--breakdown"],
                ["npx", "ccusage@latest", "--json", "--breakdown"]):
        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, timeout=120
            )
            if result.returncode == 0 and result.stdout.strip():
                return json.loads(result.stdout)
        except (subprocess.TimeoutExpired, json.JSONDecodeError,
                FileNotFoundError):
            continue
    raise RuntimeError(
        "ccusage 실행에 실패했습니다. `npx ccusage --json` 을 직접 "
        "실행해 오류를 확인하세요."
    )


def aggregate_month(
    data: dict, month: str, user: str
) -> List[Dict[str, object]]:
    """일별 데이터를 월/모델 단위로 집계합니다.

    Args:
        data: ccusage JSON (daily 항목 포함)
        month: 대상 월 (YYYY-MM)
        user: 사용자 이름

    Returns:
        CSV 행 딕셔너리 리스트 (모델별 1행)
    """
    rows: Dict[str, Dict[str, object]] = {}
    for day in data.get("daily", []):
        day_key = day.get("period") or day.get("date") or ""
        if not str(day_key).startswith(month):
            continue
        breakdowns = day.get("modelBreakdowns") or [day]
        for item in breakdowns:
            model = item.get("modelName", item.get("model", "unknown"))
            row = rows.setdefault(model, {
                "month": month, "user": user, "model": model,
                "input_tokens": 0, "output_tokens": 0,
                "cache_read_tokens": 0, "cache_write_tokens": 0,
                "total_cost_usd": 0.0,
            })
            row["input_tokens"] += item.get("inputTokens", 0)
            row["output_tokens"] += item.get("outputTokens", 0)
            row["cache_read_tokens"] += item.get(
                "cacheReadTokens", item.get("cacheReadInputTokens", 0))
            row["cache_write_tokens"] += item.get(
                "cacheCreationTokens",
                item.get("cacheCreationInputTokens", 0))
            row["total_cost_usd"] += item.get(
                "cost", item.get("totalCost", 0.0))
    return list(rows.values())


def write_report(
    rows: List[Dict[str, object]],
    month: str,
    user: str,
    output_dir: Path,
) -> Path:
    """CSV 파일과 요약 Markdown 을 출력합니다.

    Args:
        rows: 모델별 집계 행
        month: 대상 월 (YYYY-MM)
        user: 사용자 이름
        output_dir: 출력 디렉토리

    Returns:
        생성된 CSV 파일 경로
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    csv_path = output_dir / f"claude_usage_{month}_{user}.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        for row in rows:
            row["total_cost_usd"] = round(
                float(row["total_cost_usd"]), 4)
            writer.writerow(row)

    total = sum(float(r["total_cost_usd"]) for r in rows)
    print(f"## Claude 사용량 리포트 — {month} ({user})\n")
    print(f"- CSV: {csv_path}")
    print(f"- 총 비용(추정): ${total:.2f}")
    for row in sorted(rows, key=lambda r: -float(r["total_cost_usd"])):
        share = (float(row["total_cost_usd"]) / total * 100
                 if total else 0.0)
        print(f"  - {row['model']}: ${row['total_cost_usd']:.2f}"
              f" ({share:.0f}%)")
    print("\n> 참고: ccusage 는 로컬 트랜스크립트 기반 추정치로 실제 "
          "청구액과 다를 수 있습니다.")
    return csv_path


def main(argv: Optional[List[str]] = None) -> int:
    """CLI 진입점."""
    parser = argparse.ArgumentParser(
        description="Claude 사용량 팀 포맷 리포트 생성")
    parser.add_argument(
        "--month", default=date.today().strftime("%Y-%m"),
        help="대상 월 (YYYY-MM, 기본: 이번 달)")
    parser.add_argument(
        "--output", default=".", help="출력 디렉토리 (기본: 현재 폴더)")
    args = parser.parse_args(argv)

    try:
        data = run_ccusage()
    except RuntimeError as e:
        print(f"오류: {e}", file=sys.stderr)
        return 1

    user = getpass.getuser()
    rows = aggregate_month(data, args.month, user)
    if not rows:
        print(f"{args.month} 에 해당하는 사용 기록이 없습니다.",
              file=sys.stderr)
        return 1
    write_report(rows, args.month, user, Path(args.output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
