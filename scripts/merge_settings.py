#!/usr/bin/env python3
"""settings.json 병합기 — base + 프로필 patch + 기존 로컬 → 최종 settings.json

병합 규칙
- 배열: 합집합 (base → patch → 로컬 순서 유지, 중복 제거)
        로컬에서 "항상 허용"으로 쌓인 권한이 재설치로 사라지지 않게 하기 위함
- 객체: 재귀 병합
- 스칼라: repo 가 정의한 값이 우선. repo 가 언급 안 한 키만 로컬 값 유지

repo 에 없는 로컬 전용 배열 항목은 stderr 로 보고한다 (정리는 사람이 판단).

usage: merge_settings.py BASE PATCH LOCAL OUT
"""
import json
import sys
from pathlib import Path


def load(path):
    p = Path(path)
    if not p.exists():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8") or "{}")
    except json.JSONDecodeError as e:
        sys.exit(f"ERROR: {path} 파싱 실패 — {e}")


def union(*lists):
    """순서를 지키면서 중복 제거."""
    seen, out = set(), []
    for lst in lists:
        for item in lst:
            key = json.dumps(item, sort_keys=True, ensure_ascii=False)
            if key not in seen:
                seen.add(key)
                out.append(item)
    return out


def merge(repo, local):
    """repo(base+patch 이미 합쳐진 것) 위에 local 을 얹는다."""
    if isinstance(repo, dict) and isinstance(local, dict):
        out = dict(repo)
        for k, v in local.items():
            out[k] = merge(repo[k], v) if k in repo else v
        return out
    if isinstance(repo, list) and isinstance(local, list):
        return union(repo, local)
    # 스칼라 또는 타입 불일치 — repo 가 정의했으면 repo 우선
    return repo


def collect_arrays(node, prefix=""):
    """{경로: 배열} 로 평탄화 — 로컬 전용 항목 보고용."""
    found = {}
    if isinstance(node, dict):
        for k, v in node.items():
            found.update(collect_arrays(v, f"{prefix}.{k}" if prefix else k))
    elif isinstance(node, list):
        found[prefix] = node
    return found


def main():
    if len(sys.argv) != 5:
        sys.exit(__doc__)
    base_p, patch_p, local_p, out_p = sys.argv[1:5]

    repo = merge(load(base_p), load(patch_p))  # patch 가 base 를 보강
    local = load(local_p)
    result = merge(repo, local)

    # repo 에 없는 로컬 전용 항목 보고
    repo_arrays, local_arrays = collect_arrays(repo), collect_arrays(local)
    extras = {
        path: [x for x in items if x not in repo_arrays.get(path, [])]
        for path, items in local_arrays.items()
    }
    extras = {k: v for k, v in extras.items() if v}
    if extras:
        print("[settings] repo 베이스라인에 없는 로컬 항목 (유지됨 — 정리는 직접 판단):",
              file=sys.stderr)
        for path, items in extras.items():
            for item in items:
                print(f"    {path}: {json.dumps(item, ensure_ascii=False)}", file=sys.stderr)

    Path(out_p).write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
