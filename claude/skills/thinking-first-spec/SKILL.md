---
name: thinking-first-spec
description: Develop a 5-section specification document (problem definition / concretization / success criteria / required artifacts / deployment scenario) from a vague problem by capturing the user's intuition first, narrowing ambiguity through one-question-at-a-time Socratic Q&A with weakest-dimension targeting, parking unresolved items in a queue, separating exploratory candidates from final decisions, and producing an integrated output with inline citations to the Q&A rounds. This skill should be used when the user wants their own intuition to seed the specification, when previous attempts felt like "the system is asking, not me thinking", when a problem is too open-ended to start coding, or when the user explicitly asks to "spec it out", "명세 만들자", "문제 정의부터 정리하자", "thinking first". At cycle start, the user explicitly chooses the work-folder root (instead of auto-resolution) so artifacts land where they want long-term. Outputs are saved per-task under `<chosen-root>/.spec-flow/{slug}/`. The skill ships with a parking-lot queue for "no good answer in the options" cases and a central registry (`~/.claude/.spec-flow/registry.json`) that indexes all spec-flow tasks across project roots so multi-day specs resume cleanly from any working directory.
---

# Thinking First Spec

## Purpose

Convert a vague problem into a decision-ready specification (5 sections) without losing the user's own intuition along the way. The skill exists because option-first questioning truncates the user's domain sense, autonomous spec drafting overwhelms with unfiltered candidates, and most workflows leave unresolved items invisible. This skill flips the order: user-intuition first, then system narrows.

## When to Use

- The user has an open-ended problem (customer requirement, research direction, product idea) and wants a written spec before writing any code.
- The user signals intuition-first preference: "I have ideas, listen first", "내 생각부터 말할게", or asks for a spec without immediately giving acceptance criteria.
- A previous skill (autopilot/brainstorming/native) produced output but the user reported "too many candidates", "couldn't choose", or "options didn't include what I meant".
- The user wants the spec saved per-task with continuity across multiple sessions.

## When NOT to Use

- The task is a single concrete code change with clear scope. Use direct edits or a code-execution skill.
- The user explicitly asks to skip planning ("just do it"). Respect that.
- An implementation plan or PRD already exists. Use a planning/execution skill on top of it.
- The problem is small enough that a 5-section spec would be more overhead than value.

## Core Principles

1. **User intuition leads, system follows.** Never present options before the user has had one chance to describe the problem in their own words.
2. **One question per round.** Never batch. Every round names the weakest dimension and explains why it is the next target.
3. **Ambiguity is a number.** Score clarity per dimension (Goal / Constraints / Success Criteria), compute weighted ambiguity, and gate progression until ambiguity ≤ 0.20.
4. **No silent dropouts.** Any "Other" / "I don't know" / off-option answer goes into a parking-lot queue and is revisited explicitly before the final spec.
5. **Decisions and assumptions are labeled.** Every load-bearing line in the final output starts with `Decision:` or `Assumption:`.
6. **Scope is bounded explicitly.** Maintain a non-goals list from S0 onward; refuse to drift into out-of-scope topics even if the user veers there.

## File Layout (per task)

The work-folder root (`<chosen-root>`) is selected explicitly by the user at cycle start (see `Pre-S0.5. Root Selection`). All artifacts land under `<chosen-root>/.spec-flow/`. Resume across multiple roots is handled by the central registry, not by per-root pointers.

The layout has two states: **in-flight** (during S0–S3, work files separated for staged isolation) and **final** (after S5 close, work files consolidated into a single `trace.md` for easier management and follow-up).

### In-flight (during S0–S3, or while status = active/parked)

```
<chosen-root>/.spec-flow/
└── <slug>/                      # human-readable topic, e.g. ict-pdm-1line-poc
    ├── _meta.json               # task_id (uuid), started_at, last_touched_at, status
    ├── intuition.md             # S0: user's filled template (or chat-dump fallback)
    ├── assumption-map.md        # S1: extracted assumptions, each confirm/reject
    ├── qna-rounds.md            # S2: per-round Q/A/score/rationale/ontology
    ├── parking-lot.md           # S2.5: unresolved items queue
    ├── candidates.md            # S3: divergent candidate list (reference)
    ├── decisions.md             # S3: convergent decisions with chosen option
    └── output.md                # S4: integrated 5-section spec with inline citations
```

### Final (after S5 `Done — close`)

On `Done — close` only, S5 consolidates the 6 work files into a single `trace.md` and renames `output.md` → `spec.md`. Final state:

```
<chosen-root>/.spec-flow/
└── <slug>/
    ├── _meta.json               # status = done
    ├── spec.md                  # final deliverable (renamed from output.md)
    └── trace.md                 # consolidated audit trail (intuition + assumption-map + qna-rounds + parking-lot + candidates + decisions)
```

`Park for now` and `Add one more round` do NOT trigger consolidation — work files stay so the next session can resume cleanly.

`_meta.json` schema:

```json
{
  "task_id": "<uuid4>",
  "slug": "<slug>",
  "started_at": "<ISO 8601>",
  "last_touched_at": "<ISO 8601>",
  "status": "active | done | parked"
}
```

## Central Registry

전 사용자 spec-flow 작업물의 인덱스를 `~/.claude/.spec-flow/registry.json`에 누적한다. 어느 root에서 사이클을 돌렸든 한 곳에서 모두 보인다 — 이로써 cwd가 어디든 resume이 가능하고, 작업물이 흩어져도 추적된다.

### Registry path

`~/.claude/.spec-flow/registry.json` (사용자 home 기준 고정). 디렉터리·파일이 없으면 첫 사이클 시작 시 자동 생성:

```bash
mkdir -p ~/.claude/.spec-flow
[ -f ~/.claude/.spec-flow/registry.json ] || echo '{"version":1,"tasks":[]}' > ~/.claude/.spec-flow/registry.json
```

### Schema

```json
{
  "version": 1,
  "tasks": [
    {
      "slug": "<kebab>",
      "title": "<spec H1 또는 slug>",
      "task_id": "<uuid4>",
      "root_path": "<chosen-root absolute>",
      "spec_path": "<chosen-root>/.spec-flow/<slug>",
      "status": "active | done | parked",
      "started_at": "<ISO 8601>",
      "last_touched_at": "<ISO 8601>",
      "closed_at": "<ISO 8601> | null"
    }
  ]
}
```

### Lifecycle events (skill이 자동 갱신)

| 이벤트 | 갱신 |
|---|---|
| S0 slug confirm | append 새 entry — status=active, started_at=now, last_touched_at=now, title=slug, closed_at=null |
| S2~S4 라운드 진행 | 각 라운드 / S3·S4 단계 종료 시 last_touched_at 갱신 |
| S4 output.md 작성 직후 | title 필드를 output.md H1 텍스트로 갱신 |
| S5 Done — close | status=done, closed_at=now, last_touched_at=now |
| S5 Park | status=parked, last_touched_at=now |
| Resume 진입 | last_touched_at 갱신 |

Concurrency: 단일 사용자 1세션 가정. 동시쓰기 보호 불필요. 안전 갱신은 임시 파일 + rename 패턴 권장(강제 아님).

`<root>/.spec-flow/current.txt`는 **deprecated** — 더 이상 만들지 않으며 기존 cycle에서 만들어진 파일은 무시한다.

## Resume Behavior

각 invocation 시작에서:

1. `~/.claude/.spec-flow/registry.json` 로드 (없으면 위 init 명령으로 생성 후 빈 list).
2. `status ∈ {active, parked}` 인 task 들을 `last_touched_at` 내림차순 정렬.
3. **활성/parked task 0건** → 곧장 `Pre-S0.5. Root Selection`으로 진행.
4. **1건 이상** → `AskUserQuestion`: "이어서 작업할 task를 골라주세요"
   - 활성/parked task 목록 (slug · status · last_touched_at · root_path 짧게)
   - "Start new" 옵션
   - 첫 옵션은 가장 최근 active, 없으면 가장 최근 parked.
5. 기존 task 선택 시: `<spec_path>/_meta.json` 읽고 last_touched_at 갱신(_meta.json + registry 양쪽), 어느 stage가 빠졌는지 파일 존재 기반으로 판단해 그 지점부터 진행.
6. "Start new" 선택 시: `Pre-S0.5. Root Selection` → `S0. Intuition Capture`로 진행.

## Stages

### Pre-S0. Permission Heads-up

본 스킬은 한 사이클 안에 6~10회의 Write/Edit를 `.spec-flow/<slug>/` 아래에 수행한다. default permission 모드라면 매번 승인 프롬프트가 떠 흐름이 끊기므로, 사이클 시작 직전에 사용자에게 옵션을 한 번만 안내한다 (안내만 하고 즉시 S0로 진행 — 사용자 응답을 기다리지 않는다):

1. **즉효**: `/permissions` 또는 ⌥+M 으로 세션 한정 `acceptEdits` 토글
2. **지속**: `~/.claude/settings.json` 또는 프로젝트 `.claude/settings.json`에 `.spec-flow/**` 경로의 Write·Edit allow 규칙 추가
3. **자동**: `/fewer-permission-prompts` 스킬로 세션 로그 기반 allowlist 자동 생성

### Pre-S0.5. Root Selection

신규 사이클 ("Start new" 또는 registry에 active/parked가 0건일 때) 진입 시, `<chosen-root>/.spec-flow/<slug>/`의 `<chosen-root>` 자체를 사용자에게 명시적으로 묻는다. 자동 탐색 후 fallback으로 cwd를 쓰던 종전 동작은 폐기 — sticky cwd로 의도치 않은 위치(다른 레포 내부)에 spec이 생기는 사고를 막는다.

Procedure:
1. Candidates 수집 (dedup 후 최대 4개):
   - **CLAUDE.md ancestor of cwd** (있으면) — 보통 사용자가 의도한 프로젝트 루트
   - **cwd 자체** — 위와 같으면 dedup
   - **레지스트리 last-used root 2건** — `last_touched_at` 내림차순 root_path
2. `AskUserQuestion`: "이번 spec의 작업물을 어디에 만들까요?"
   - 첫 옵션 = 추천 (CLAUDE.md ancestor가 있으면 그것, 없으면 cwd)
   - 나머지는 위 candidates
   - free-text 응답은 **절대 경로**로 처리. 상대 경로는 cwd 기준 해석.
3. 선택된 `<chosen-root>` 확정. `<chosen-root>/.spec-flow/`가 없으면 `mkdir -p`로 생성.
4. 이후 모든 S0~S5 산출물은 `<chosen-root>/.spec-flow/<slug>/` 아래에 만든다. `<chosen-root>`는 사이클 종료까지 sticky.

### S0. Intuition Capture (template-first)

Goal: capture the user's raw mental model into a scaffolded markdown file the user fills in (or pastes existing notes into) at their own pace. Chat-based free-form dump is the fallback path, not the default.

Procedure:
1. Greet briefly and explain the template-first flow. Tell the user: "intuition 입력 양식 파일을 만들어 드릴게요. 자유롭게 채우거나 기존에 정리해둔 노트를 그대로 복붙해도 됩니다. 다 됐으면 채팅에 신호만 주세요."
2. Create `<chosen-root>/.spec-flow/_pending-intuition.md` with the template below. The file lives at parent level (slug not determined yet — slug will derive from filled content):

   ```markdown
   # Intuition Draft

   _본 파일은 thinking-first-spec S0 입력 양식입니다. 채워주신 후 채팅에 신호("ㅇㅋ", "go", "다 됐어" 등)를 주세요. 빈 칸은 그대로 둬도 OK._

   ## 1. 무엇을 하고 싶은가 (What)

   <여기에 한 줄~여러 줄로 적어주세요>

   ## 2. 왜 필요한가 (Why)

   <왜 지금 이걸 풀려고 하는지 / 안 풀면 무엇이 잃어지는지>

   ## 3. 자유 형식 (Free-form notes)

   <막힌 지점·추측되는 답·기존 자료 무엇이든. 사전에 정리해둔 글이 있으면 그대로 복붙 OK.>
   ```

3. Wait for the user's completion signal in chat. Do not proceed before signal — the file may be empty until they save.
4. Re-read `_pending-intuition.md`. The user-filled content (excluding template instructions) is the canonical intuition. If all three sections are blank, prompt the user once: "양식이 비어 있어요. 한 줄이라도 채워주시거나, 채팅에 직접 적어주시면 그대로 받겠습니다 (fallback 경로)."
5. Extract a candidate slug (kebab-case, ≤4 words) from the filled content and confirm via `AskUserQuestion`: "이 작업을 `<slug>`로 부를까요?" with options `[Yes, Suggest different]`.
6. On confirm: create `<chosen-root>/.spec-flow/<slug>/` folder and **move** `_pending-intuition.md` to `<slug>/intuition.md` (Bash `mv`). Do NOT copy — the parent-level draft must not linger.
7. Initialize `<slug>/_meta.json` with task_id (uuid), started_at (ISO 8601), last_touched_at (same), status=active.
8. **Append a new entry to the central registry** (`~/.claude/.spec-flow/registry.json`):
   - `slug`, `task_id`, `root_path = <chosen-root>`, `spec_path = <chosen-root>/.spec-flow/<slug>`, `status = active`, `started_at`, `last_touched_at`, `closed_at = null`, `title = <slug>` (S4 후 spec H1로 갱신).
   - Read → modify in memory → Write 패턴. 임시 파일 + rename으로 안전 갱신 권장.

**Fallback (chat-based dump)**: if the user prefers to type directly into chat ("그냥 여기 적을게") or step 4 detects all-blank template, accept that as legacy path — capture the raw text verbatim into `<slug>/intuition.md` after slug confirmation. The template is the default; chat-dump is the fallback.

Do NOT score ambiguity yet. Do NOT propose options yet.

### S1. Intuition → Question Map (system extracts, user confirms)

Goal: turn the freeform intuition into a structured map of explicit assumptions, implicit assumptions, contradictions, and core entities — without adding new options.

Procedure:
1. Re-read `intuition.md`.
2. Produce, in `assumption-map.md`:
   - **Explicit decisions the user already made** (verbatim quotes with line refs).
   - **Implicit assumptions** (things the user said as if obvious but are choices).
   - **Internal contradictions or missing pieces** (places where the user said two things that don't compose).
   - **Core entities (nouns)** with one-line definitions.
3. For each item, apply the cycle below. Free-text answers go straight to `parking-lot.md`.
   - **Implicit assumptions** and **internal contradictions/missing pieces**: these are real decision points. Present each via `AskUserQuestion` with options `[Confirm, Reject, Reword]` — cycle through them one at a time.
   - **Explicit decisions** (verbatim user quotes) and **core entity definitions**: these are informational. Present them as a single read-only summary block in chat — no per-item AskUserQuestion needed. They are still recorded in `assumption-map.md` for the audit trail.
4. Persist the user's confirm/reject/reword next to each implicit/contradiction item in `assumption-map.md`.

This stage is bounded: stop after every extracted item has a verdict. Do not loop back to add new items here.

### S2. Ambiguity-Gated Q&A

Goal: drive ambiguity below 0.20 via one-question-per-round Socratic Q&A.

Per round:
1. Score current clarity in three dimensions, each 0.0–1.0:
   - **Goal Clarity** (weight 0.40): is the primary objective stated in one sentence with named entities?
   - **Constraint Clarity** (weight 0.30): are boundaries, label availability, time grain, real-time vs batch, domain-knowledge access stated?
   - **Success Criteria Clarity** (weight 0.30): could a test be written? Is the KPI named?
   - Ambiguity = `1 − (goal*0.40 + constraints*0.30 + criteria*0.30)`.
2. Identify the **weakest dimension** (lowest score). State explicitly: "이번 라운드 목표는 X — 점수 Y, 갭 Z 때문에 가장 약함."
3. Generate one question targeting that dimension. Construct option labels by drawing **first** from the user's own words (`assumption-map.md`, prior rounds, parking-lot), and **second** from system-suggested candidates clearly labeled as such (e.g. "Option C [system-suggested]").
4. Ask via `AskUserQuestion` (one question, ≤4 options + the auto-provided free text). Free-text answers go to `parking-lot.md` AND the round record.
5. Re-score after the answer. Append to `qna-rounds.md`:
   - Round number, weakest dimension, targeting rationale, question text, options, user answer, new scores, ambiguity delta, ontology entities updated this round.
6. Track ontology entities: append/merge into `qna-rounds.md`'s ontology table. Watch for stability (entities that survive ≥2 rounds with same name).

Stop conditions:
- **Pass:** Ambiguity ≤ 0.20 and ontology stable for 2 consecutive rounds → proceed to S2.5.
- **Soft warning:** at round 8, surface "이미 8라운드입니다. 계속 / 이쯤에서 멈춤?" once.
- **Hard cap:** 12 rounds. Force-proceed with current clarity, note the risk in `output.md`.
- **Early exit:** user says "그만", "이쯤에서". Proceed but log unresolved gaps to `parking-lot.md`.

**Continuation discipline**: 사용자의 `AskUserQuestion` 답변 자체가 다음 단계로의 진행 신호다. 답변을 받은 즉시 한 응답 안에서 (1) `qna-rounds.md` / `parking-lot.md` 기록 → (2) 재점수 산정 → (3) stop condition 평가 → (4) 통과면 S2.5로 / 미통과면 다음 라운드 질문 출력 — 까지를 수행한다. 사용자에게 "다음으로 넘어갈까요?" 같은 추가 컨펌을 묻지 않는다. 같은 원칙이 S1 verdict 사이클과 S2.5 sweep에도 적용된다.

Do not skip the visible scoring. The number itself is part of the value.

### S2.5. Parking-Lot Sweep

Goal: ensure no off-option / "I don't know" answer disappears.

Procedure:
1. Read `parking-lot.md`. Group items by entity / dimension / round.
2. For each group, present via `AskUserQuestion` with options `[Resolve now, Promote to assumption, Defer to later cycle]`.
3. Resolved items move into `decisions.md`. Promoted items become labeled `Assumption:` lines for the final output. Deferred items stay in `parking-lot.md` with a `[deferred]` tag.
4. Do NOT advance to S3 with un-triaged parking-lot items.

### S3. Divergence / Convergence Split

Goal: separate "all options that were on the table" from "what was chosen", so the rejected paths are preserved without polluting the final spec.

Procedure:
1. Write `candidates.md`: bullet list of every option discussed in S2 (per dimension), including system-suggested ones, even if rejected. Format:
   ```
   ## <Dimension>
   - [chosen] Option A — chosen at round N because ...
   - Option B — rejected at round N because ...
   - Option C [system-suggested] — not chosen
   ```
2. Write `decisions.md`: only the chosen options, each with a `Decision:` label and a one-line citation to the round number.

Do not write the final 5-section spec yet. This stage exists to keep the audit trail visible.

### S4. Integrated 5-Section Spec

Goal: produce `output.md` answering the 5 sections in order, every load-bearing line labeled and cited.

Section structure (REQUIRED — match this exactly):

```markdown
# 명세 산출물: <Title>

## 0. 범위 및 비범위 (Scope / Non-Goals)
- in-scope (Decision:)
- non-goals (Decision:)

## 1. 문제 정의 (Problem Definition)
- 핵심 문제
- 감지/처리 단위 표
- 풀 가치 (누가 / 어떤 손실)

## 2. 구체화 (Concretization)
- 입력 데이터 스키마 (표)
- 출력 스키마 (표)
- 명시적 가정·제약

## 3. 목적 명확화 (Success Criteria)
- 1차 KPI (정의 + 계산식)
- 보조 관측
- 평가 주체와 시점

## 4. 필요 항목 정리 (Required Artifacts)
- 데이터
- 모델/방법론 후보 (통계 / ML / 도메인 룰 ≥1개씩)
- 인프라
- 지표
- 도메인지식

## 5. 활용 방법 (Deployment Scenario)
- 운영 시나리오 1줄 흐름 (누가 / 언제 / 어떤 알림 / 어떤 조치)
- 단계적 도입 (PoC → 파일럿 → 확대)
- 피드백 회수 루프
- 성공/실패 판정 기준

## Appendix A. 가정·결정 추적 (인덱스)
| 항목 | 라벨 | 출처 |
|------|------|------|
| ... | Decision: / Assumption: | round N / parking-lot Q.X / S1 confirm |

## Appendix B. 산출 경로
- `<project-root>/.spec-flow/<slug>/spec.md` — 본 문서 (S5 close 후 이름; S4 시점에는 `output.md`)
- `<project-root>/.spec-flow/<slug>/trace.md` — S0~S3 audit trail (S5 close 시 work files 병합 생성)
```

Rules:
- Every load-bearing line in §0–§5 starts with `Decision:` or `Assumption:`.
- Every decision has an inline citation to its origin (e.g. `(round 4)`, `(parking-lot Q.2)`, `(S1 confirm)`).
- No "더 알아봐야 한다" / "TBD" / "to be determined" phrasings. Convert all such items to explicit `Assumption:` lines OR push to `parking-lot.md` with `[deferred]`.
- Keep §4 "모델/방법론 후보" structurally diverse — at least one entry each in 통계 / ML / 도메인 룰.

After writing, set `_meta.json.status = active` (still active until S5 confirms).

### S5. Closing Gate

Goal: brief user-facing close that records satisfaction and lifecycle state, and (on `Done`) consolidate intermediate files into the final 2-file deliverable.

Procedure:
1. Show the user a 5-line summary: rounds run, final ambiguity %, parking-lot deferred count, slug, output.md path.
2. Ask via `AskUserQuestion`: "이 사이클을 마칠까요?" with options `[Done — close, Add one more round, Park for now]`.
3. On `Done`:
   a. Run **Trace consolidation** (see below) — merges 6 work files into `trace.md`, deletes originals.
   b. Rename `output.md` → `spec.md` (Bash: `mv`).
   c. Patch `spec.md`'s Appendix B to reference `trace.md` (Edit).
   d. Set `_meta.json.status = done`, `closed_at = now`.
   e. **Update registry entry** (`~/.claude/.spec-flow/registry.json`): `status = done`, `closed_at = now`, `last_touched_at = now`, `title = <spec.md H1 텍스트>`.
   f. Output a final pointer line with paths to `spec.md` and `trace.md`.
4. On `Add one more round`: return to S2 with current ambiguity. No consolidation. Update registry `last_touched_at`.
5. On `Park`: set `_meta.json.status = parked`. **Update registry entry**: `status = parked`, `last_touched_at = now`. No consolidation — work files stay for next-session resume.

### Trace consolidation (executed only on `Done — close`)

Merge the 6 work files into `<slug>/trace.md` with this structure (verbatim concatenation under section anchors — do not rewrite):

```markdown
# Trace — <slug>

_본 문서는 spec.md 의 audit trail입니다. 모든 결정·가정의 근거를 라운드 단위로 추적할 수 있습니다._

## 요약
- Slug: <slug>
- Rounds run: N
- Final ambiguity: 0.XX
- Parking-lot deferred: K건
- Closed at: <ISO 8601>

## 목차
- [S0. Intuition Dump](#s0-intuition-dump)
- [S1. Assumption Map](#s1-assumption-map)
- [S2. Q&A Rounds](#s2-qa-rounds)
- [S2.5. Parking Lot](#s25-parking-lot)
- [S3. Candidates (divergent)](#s3-candidates-divergent)
- [S3. Decisions (convergent)](#s3-decisions-convergent)

## S0. Intuition Dump
<intuition.md 본문 그대로>

## S1. Assumption Map
<assumption-map.md 본문 그대로>

## S2. Q&A Rounds
<qna-rounds.md 본문 그대로>

## S2.5. Parking Lot
<parking-lot.md 본문 그대로>

## S3. Candidates (divergent)
<candidates.md 본문 그대로>

## S3. Decisions (convergent)
<decisions.md 본문 그대로>
```

Rules for consolidation:
- **Verbatim concatenation.** Preserve every line of source files. The trace is an archive, not a rewrite.
- **Header demotion.** Each work file's top-level `#` becomes `##` under the unified TOC; existing `##` headers inside the file (e.g., `## Round 1` in qna-rounds.md) become `###`. This keeps anchors functional and prevents header-level collisions.
- **Anchor format.** Use GitHub-flavored markdown anchors (lowercase, punctuation removed, spaces → hyphens). Verify TOC links resolve to actual headers before deletion of source files.
- **Delete originals only after `trace.md` write succeeds.** Order: (1) write `trace.md`, (2) verify it exists with non-empty body, (3) `rm` the 6 work files (Bash). Never delete-then-write.

## Stages Deferred (do not implement yet)

A model-led "S6 verification / pair-review" stage was discussed during design and intentionally deferred. It would surface domain-general blind spots the user did not know to ask about (challenger mode with `[domain-general]` / `[from-user]` / `[from-prior-rounds]` provenance labels). Add this only after S0–S5 has been used on real tasks and a concrete need is observed. Keep this skill stable until then.

## Tool Usage

- `AskUserQuestion`: every question in S0 confirm, S1, S2, S2.5, S5. Always one question, ≤4 structured options + the auto-provided free text. Free-text answers always go to `parking-lot.md` in addition to wherever they would normally go.
- `Read`: read `intuition.md`, `assumption-map.md`, `qna-rounds.md`, `parking-lot.md`, `_meta.json`, `~/.claude/.spec-flow/registry.json` between stages.
- `Write`: create new files. `Edit`: update `qna-rounds.md`, `parking-lot.md`, `_meta.json`, `~/.claude/.spec-flow/registry.json` incrementally.
- `Bash`: only for filesystem operations the dedicated tools cannot do — finding the `CLAUDE.md` ancestor for Pre-S0.5 candidates (`d="$PWD"; while [ "$d" != "/" ]; do [ -f "$d/CLAUDE.md" ] && echo "$d" && break; d=$(dirname "$d"); done`), generating UUID (`uuidgen`), getting ISO timestamp (`date -u +%FT%TZ`), initializing the central registry (`mkdir -p ~/.claude/.spec-flow && [ -f ~/.claude/.spec-flow/registry.json ] || echo '{"version":1,"tasks":[]}' > ~/.claude/.spec-flow/registry.json`), moving `_pending-intuition.md` → `<slug>/intuition.md` at S0 close, and S5 close consolidation (`mv output.md spec.md`, `rm` of 6 work files after `trace.md` is verified non-empty).
- Do NOT spawn subagents in this skill. The whole flow is single-context-window — preserving the user's intuition through the run is part of the design.
- **Korean text in tool arguments**: `AskUserQuestion`의 `question`/`label`/`description` 등 도구 인자 안에서 한글을 다룰 때 `\uXXXX` unicode escape를 쓰지 말고 한글 그대로 작성한다. escape 경로에서 일부 글자가 다른 글자로 손상되어 사용자에게 잘못된 단어가 노출되는 사례가 있다 (실측: "스타일"→"쌑타일", "섞이나요"→"티겁"). 영문·기호는 escape OK.

## Output Quality Gates (before declaring done)

Verify before saying done. Gates 1–7 run at S4 boundary (still `output.md`); gate 8 runs after S5 close consolidation.

1. `output.md` has all 5 sections + Appendix A + Appendix B with non-empty bodies.
2. Every load-bearing line in §0–§5 begins with `Decision:` or `Assumption:`.
3. Every `Decision:` line has an inline citation.
4. `parking-lot.md` either is empty or contains only `[deferred]` items.
5. `_meta.json.status` reflects the actual closing state.
6. The non-goals list in §0 was honored — grep `output.md` for any of the listed non-goal terms; if present, audit context.
7. No code blocks, no notebook references, no dataset paths in `output.md` if the user said "no code". Match the input constraint exactly.
8. (Post-S5 close only) `<slug>/` contains exactly `_meta.json`, `spec.md`, `trace.md` — no work file leftovers and **no `current.txt` (deprecated)**. The central registry entry for this slug has `status=done` with `closed_at` set and `title` updated from the spec H1. `trace.md` body is non-empty and contains all 6 section anchors (`## S0`, `## S1`, `## S2`, `## S2.5`, `## S3. Candidates`, `## S3. Decisions`).

## Examples

### Good — Template-first capture
User: "ICT 검사 데이터로 부품 불량 사전 감지 명세 만들고 싶어"
Skill: creates `_pending-intuition.md` with What / Why / Free-form template, says "이 파일에 자유롭게 채우거나 기존 노트를 복붙해 주세요. 다 됐으면 신호 주세요." [waits for signal, re-reads file, derives slug=`ict-pdm-1line-poc`, moves file to `<slug>/intuition.md`, proceeds to S1]

### Good — Chat-fallback capture
User: "그냥 여기 적을게 — ICT 검사 데이터로..."
Skill: accepts chat-based dump as fallback path, captures verbatim into `<slug>/intuition.md` after slug confirm. Template was offered first but user opted out — that's allowed.

### Bad — Option-first
Skill: "감지 단위는 (a) 부품 (b) 제품 (c) 라인 중 무엇입니까?"
Why bad: forecloses the user's own framing before the user has spoken.

### Good — Parking-lot honored
User answers Round 3 with "그건 잘 모르겠다 — 확인이 필요해."
Skill: writes to `parking-lot.md` with round/dimension context, AND continues round with a fallback option, AND surfaces the item in S2.5 sweep.

### Bad — Silent dropout
Skill ignores "잘 모르겠다" and proceeds without recording.
Why bad: the unresolved item disappears and may never be revisited.

### Good — Inline citation
`Decision: 1차 KPI = retrospective hit-rate (round 5)`

### Bad — Bare claim
`1차 KPI는 retrospective hit-rate.`
Why bad: no label, no provenance — fails Quality Gate 2 and 3.
