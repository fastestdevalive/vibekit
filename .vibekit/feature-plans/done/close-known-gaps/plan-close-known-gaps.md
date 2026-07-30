<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# Plan: close the three known gaps

**Status:** Done — closed 2026-07-30
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26`

Three gaps stated in PR #3. Each is independent; do them in order.

---

## Gap 1 — eval coverage (43 of 46 unfixtured)

**Not** "build all 43." Build the fixtures for machinery most likely to be wrong and least likely to be noticed, then mark the rest honestly.

### Priority fixtures — build these

| Case | Verifies | Why it matters |
|------|----------|----------------|
| **E34** | `/sdlc continue` at `awaiting_phase: review` clears the pause, reaches `done/` | The drain deadlock we fixed — regression here silently strands every feature |
| **E14** | Delegate returns; parent **re-runs verify**, does not trust `[x]` | Handoff is the #1 real workflow (324 history hits) |
| **E16** | Reviewer rejected `max_iterations` times → escalates, no 3rd iteration | Unbounded review loop otherwise |
| **E36** | `/sdlc continue` with nothing awaiting → says so, falls through to resume | Undefined behavior is worse than refusal |
| **E37** | Fresh session, `awaiting_*` set → restates and asks, never auto-advances | The pause's entire value is surviving context loss |
| **E13** | State says complete, checklist has unchecked items → checklist wins | Two sources of truth; precedence must hold |
| **E12** | Plan touching >1 layer with no boundary contract → review FAILS it | The unscalable-interface problem |
| **E22** | `/sdlc prd-plan <f>` runs exactly two phases and STOPS | Chain end is a hard stop — never executed |

### Rules for every new fixture

- [x] **1.1** Build fixtures for E34, E14, E16, E36, E37, E13, E12, E22
- [x] **1.2** Each gets a **positive** assertion — a do-nothing agent must FAIL it
- [x] **1.3** Mutation-test each: seed a do-nothing prompt, confirm FAIL, restore
- [x] **1.4** Approval-gated cases get `consider this pre-approved` in the prompt (see `cases.md` headless constraints)
- [x] **1.5** "Must not act" cases assert on `.agent-output.txt` content, not just file state
- [x] **1.6** Assert the **invariant**, never the author's expected answer (the E4 lesson)
- [x] **1.7** In `cases.md`, mark every remaining case `fixtured` / `not-fixturable-headless (reason)` / `deferred`

**Verify gap 1:**
- [x] **1.T1** `./smoke.sh` clean with all new fixtures
- [x] **1.T2** `./run.sh` — every fixtured case passes
- [x] **1.T3** Each new case proven to fail via mutation (quote the FAIL line)
- [x] **1.T4** `cases.md` status column has no blank cells

---

## Gap 2 — Cursor/Gemini ship `SKILL.md` only

Companion links are inert there. `sdlc/SKILL.md` says "Read `GRAMMAR.md` before parsing any invocation" and the file is never installed.

- [x] **2.1** `adapters/cursor/install.sh` — inline companions into the `.mdc`: `SKILL.md`, then each linked companion under a clear `## ── <NAME>.md ──` separator
- [x] **2.2** `adapters/gemini/install.sh` — same, appended into `GEMINI.md`
- [x] **2.3** Both exclude `evals/` and `CONTRIBUTING.md`, matching claude-code/agy
- [x] **2.4** Emit a header line in the generated file: companions are inlined below, not separate files
- [x] **2.5** `README.md` adapter table — update the companion column to reflect inlining

**Verify gap 2:**
- [x] **2.T1** `./install.sh cursor all $T` → the `sdlc.mdc` contains text unique to `GRAMMAR.md` and `PHASES.md`
- [x] **2.T2** `./install.sh gemini all $T` → `GEMINI.md` likewise
- [x] **2.T3** Neither output contains `evals/` or `CONTRIBUTING.md` content
- [x] **2.T4** Lint check: for cursor+gemini, generated output must contain each companion's content

---

## Gap 3 — `.sdlc-state.yaml` has no canonical schema

Config got a canonical file; state is still inline in `SKILL.md` and drifted before.

- [x] **3.1** Create `sdlc-state.example.yaml` at repo root, next to `vibekit.example.yaml`
- [x] **3.2** Document every field with `[honored]` / `[spec]`, same legend as the config schema
- [x] **3.3** Cover: `feature`, `worktree`, `created`, `master.*`, `current_subfeature`, `subfeatures[]` (`id`, `origin`, `spawned_from`, `mode`, `last_completed`, `awaiting_phase`, `awaiting_artifact`, `phase_chain`, `superseded_reason`, `parked_reason`, `handoff.*`, `commit`)
- [x] **3.4** `SKILL.md` state block becomes a short example + pointer to the canonical file
- [x] **3.5** Extend `schema-check.py` to cover it — a state key referenced in docs must exist in the schema

**Verify gap 3:**
- [x] **3.T1** `sdlc-state.example.yaml` parses as YAML
- [x] **3.T2** Schema check FAILS when a documented state key is removed from it
- [x] **3.T3** No state key documented in `skills/sdlc/*.md` is absent from the canonical file

---

## Global verification

- [x] **G1** `bash skills/sdlc/evals/lint.sh` exit 0
- [x] **G2** `python3 skills/sdlc/evals/prose-lint.py` exit 0
- [x] **G3** `bash skills/sdlc/evals/smoke.sh` clean
- [x] **G4** `bash skills/planning/scaffold.sh $(mktemp -d)` exit 0
- [x] **G5** All four adapters install clean into temp dirs
- [x] **G6** `./install.sh claude-code` then `./run.sh` — every fixtured case passes

---

## Outcome

**11 fixtures, all 11 cases executed.** `E34` (drain release) and `E14` (handoff return) — the two
riskiest pieces of machinery — both pass.

| Result | Cases |
|--------|-------|
| Pass | E1 E4 E12 E13 E14 E15 E16 E22 E34 E37 |
| Fixed assertion | E36 — see below |

### E36 was a false failure — the eval was wrong, not the skill

- Assertion demanded the phrase *"nothing is awaiting"*; the agent instead resumed and
  reported progress, which is the correct behavior
- Rewritten to assert the **invariant**: forward progress happened, `continue` dispatched as a
  subcommand rather than being parsed as a feature name, and no pause was invented
- Same trap as E4's `<=2 clusters` — encoding the author's expected answer instead of the property

### The `w: unbound variable` crashes were not a code bug

- Reported at two different line numbers (154, 225) for the same symptom
- Every assert declares `w`; `bash -n` passes; a scan of all 11 found nothing
- Cause: `run.sh` was edited while a batch was executing — bash reads scripts incrementally
- Lesson worth keeping: never edit `run.sh` while a suite is running
