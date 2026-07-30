<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# Plan: `arch` / `plan` restructure of the planning skill

**Issue:** planning-doc-restructure
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26`
**Status:** Done — closed 2026-07-30

> Naming settled with the user: **`arch`** (occasional, system-level) and **`plan`** (the default).

---

## The model

| Doc | Carries implementation phases | Children are called | Frequency |
|-----|:---:|---------------------|-----------|
| **`arch`** | ❌ never | **parts** | rare — only when a feature needs system-level decomposition |
| **`plan`** | ✅ the `[x]` checklist | **sub-plans** | the default |

- **One discriminating bit: does this doc carry implementation phases?**
- `arch` decomposes into parts; each part *is* a plan
- `plan` may also decompose — into sub-plans (bug bundles, refinements) — and still carries its own checklist
- Most features have **no arch at all**: one `plan`, optionally spawning sub-plans

```
arch-auth-flow.md              (rare)
   └── part 01, part 02, part 03      each is a plan
                └── sub-plan          bug bundle spawned during implementation

plan-login-fix.md              (typical — no arch above it)
   └── sub-plan                       bug bundle spawned during implementation
```

- Parts vs sub-plans is **provenance, not structure** — both are `NN-` dirs, distinguished by the existing `origin` field:
  - `origin: planned` → a **part** (came from an arch decomposition)
  - `origin: bug-bundle | requirement-change | refinement` → a **sub-plan** (spawned from a plan)
- No new state fields needed

---

## Files: before → after

| Now | After | Role |
|-----|-------|------|
| `_plan_sample_big_feature_design.md` | `_template_arch.md` | System-level, no phases, decomposes into parts |
| `_plan_sample_small_feature_bugfix.md` | `_template_plan.md` | The default; carries the checklist |
| `FORMAT.md` | **content edit** (`:5-6` names both templates) | The rulebook |
| `SECTIONS.md` | unchanged | Per-section spec |

- `SECTIONS.md` → `SECTION-LIBRARY.md` rename **dropped** — no gain, and it breaks `skills/sdlc/SKILL.md:31`, `PHASES.md:11`, `lint.sh:31`

### H1 titles change too

| File | Now | After |
|------|-----|-------|
| `_template_arch.md` | `# Design: [Feature / System Name]` | `# Arch: [System / Feature Name]` |
| `_template_plan.md` | `# Mini-Design: [Title]` | `# Plan: [Title]` |

- Renaming the file while the heading still says "Mini-Design" would just relocate the confusion

### Artifact filenames

```
.feature-plans/<state>/<feature>/
  arch-<feature>.md                      ← only when an arch exists
  plan-<feature>.md                      ← the common case
  NN-<slug>/
    plan-<NN>-<feature>-<slug>.md        ← a part (from arch) or a sub-plan (from a plan)
    screenshots/
```

- Today the arch doc is *also* named `plan-<feature>.md`, hiding the distinction — `arch-` makes it visible at a glance
- Rarity becomes legible: a feature dir with no `arch-*.md` never needed system-level design

---

## Defects this fixes

| # | Defect | Fix |
|---|--------|-----|
| 1 | **Selector picks by size** (`skills/planning/SKILL.md:48-49` — "Big feature" / "Small feature") | Select by the bit: does it carry implementation phases? |
| 2 | **`plan` template has no sub-plan tracker** — only an upward `Parent design:` link (`_plan_sample_small_feature_bugfix.md:17`); nowhere to record a bug bundle it spawned | Add `## Sub-Plan Breakdown` to `_template_plan.md` |
| 3 | **Nesting drift** — CUJs/Data Model/API/System Boundaries at `##` in arch, `###` under Design Details in plan | Nest arch's four under `## Design Details`; canon (`SECTIONS.md:19`, `FORMAT.md:90`) already says so, so the arch template is the deviant |
| 4 | Same section spec'd in `SECTIONS.md` **and** both templates | Templates carry skeleton + one-line condition; multi-line spec lives in `SECTIONS.md` only |

- **Withdrawn from the earlier draft:** "System Boundaries missing from the small template" — false, it is at `_plan_sample_small_feature_bugfix.md:112`

---

## New selector prose

Replaces `skills/planning/SKILL.md:48-49`:

```markdown
## Which template?

- **`_template_plan.md`** — the default. Carries the implementation checklist.
  Use it for any work you will actually execute, however large.
  It may spawn sub-plans (bug bundles, follow-ups) and still keeps its own checklist.

- **`_template_arch.md`** — only when a feature needs system-level decomposition
  before anything is executable. No implementation phases; its output is parts,
  each of which is a plan.

If unsure: use `plan`. Most features never need an arch.
```

- `/sdlc` picks automatically — it already knows whether it is writing a feature-level or sub-feature artifact

---

## Sections after the change

| Section | `arch` | `plan` |
|---------|:---:|:---:|
| Problem, Out of Scope, Requirements, Risks | ✅ | ✅ |
| System Context, Entities & Modules | ✅ | ✅ |
| Design Details (CUJs, Boundaries, Data Model, API Contracts) | ✅ *(newly nested)* | ✅ |
| Breakdown tracker | ✅ `## Part Breakdown` | ✅ **new** `## Sub-Plan Breakdown` |
| Alternatives Considered, Rollout Strategy | ✅ | ❌ |
| Concept, Research, Root Cause, Key Decisions | ❌ | ✅ |
| Files to Modify, Files Summary | ❌ | ✅ |
| **Implementation Phases** | ❌ **never** | ✅ **always** |

---

## Doc count stays at 4

| Option | Verdict |
|--------|---------|
| **A — `arch` + `plan` + `FORMAT` + `SECTIONS`** | ✅ Proposed |
| B — merge FORMAT + SECTIONS | ❌ ~335 lines fits the 600 companion cap, but mixes writing rules with per-section specs — two different lookup shapes in one file |
| C — one merged template | ❌ ~10 dead sections per plan; cheap agents fill dead sections, and the cost is paid on *every* plan |
| D — shared core + two extensions | ❌ Starting a plan becomes a two-file assembly job — worse for cold handoff |

- Drift between the two templates is the real cost of keeping them separate — **not** mitigated by merging. A shared-heading lint check was considered and CUT at 4.6 (the templates intentionally diverge); `2.T1`-`2.T3` pin the structure that actually matters, and `E46` (post-review) covers the one cross-template invariant worth a behavioral check: an arch doc must never carry Implementation Phases

---

## What must change

| File | Change |
|------|--------|
| `skills/planning/_plan_sample_*.md` | `git mv` ×2; H1 retitles; nest arch's 4 sections; add Sub-Plan Breakdown to plan |
| `skills/planning/SKILL.md:48-49` | New selector prose |
| `skills/planning/SECTIONS.md:9` | Names both template files |
| `skills/planning/scaffold.sh:40, 72, 145-146` | Copy list + emitted project guide text |
| `skills/sdlc/SKILL.md`, `PHASES.md` | `arch-<feature>.md` in the artifact layout; decomposition wording (parts vs sub-plans) |
| `CLAUDE.md`, root `AGENTS.md:33,37-38`, `README.md:57-59` | Repo layout |
| `skills/sdlc/evals/lint.sh` | Stale-ref check for `_plan_sample_big\|small`; shared-section-parity check |

- **Already-scaffolded projects:** accept drift; `scaffold.sh:40-47` skips existing files. No migration
- `.feature-plans/done/**` keeps old names — historical records, and lint already excludes that path

## Open questions — answered

| # | Question | Answer |
|---|----------|--------|
| 1 | Breaks scaffold? | Yes — update `scaffold.sh:40,72,145-146` in the same commit; the scaffold-exits-0 lint catches a miss |
| 2 | Split `SECTIONS.md`? | No — it stays under 200 as long as snippets stay in templates |
| 3 | Checklist in `arch`? | No — it keeps only the parts tracker; never implementation phases |
| 4 | Keep `_` prefix? | Yes — matches `_prd_sample_format.md`, sorts templates away from real plans |

## Implementation Phases

> **Sequencing note:** `report-skill` already landed. Collision is purely textual — it appended to the
> same layout blocks and to `lint.sh`. Grep for current line numbers rather than trusting those cited here.

### Phase 1 — Rename and retitle the templates

- [x] **1.1** `git mv skills/planning/_plan_sample_big_feature_design.md skills/planning/_template_arch.md`
- [x] **1.2** `git mv skills/planning/_plan_sample_small_feature_bugfix.md skills/planning/_template_plan.md`
- [x] **1.3** Retitle `_template_arch.md` H1: `# Design:` → `# Arch:`; also fix lowercase "mini-design(s)" at `:238,246`
- [x] **1.4** Retitle `_template_plan.md` H1: `# Mini-Design:` → `# Plan:`
- [x] **1.5** Update `_template_plan.md:17` frontmatter — `**Parent design:** .../design-<slug>.md` → `**Parent:** `arch-<slug>.md` or `plan-<slug>.md` _(only when spawned)_` — a sub-plan's parent is usually a plan, not an arch

**Verify phase 1:**
- [x] **1.T1** Integration — `ls skills/planning/_plan_sample_*` returns nothing
- [x] **1.T2** Integration — `grep -rni "mini-design" skills/planning/_template_*.md` returns zero hits (repo-wide check moves to 4.T6 — `skills/planning/SKILL.md:49` still says it until Phase 3)


---

### Phase 2 — Fix the structural defects

- [x] **2.1** Add `## Sub-Plan Breakdown` to `_template_plan.md` — a plan may spawn sub-plans (bug bundles); today it has only the upward parent link
- [x] **2.2** Nest `_template_arch.md`'s four sections (CUJs, Data Model, API/Contract, System Boundaries) under `## Design Details` to match canon (`SECTIONS.md:19`, `FORMAT.md:90`)
- [x] **2.3** Rename arch's `## Sub-Plan Breakdown` (`:236`) → `## Part Breakdown`; update the frontmatter tracker (`:18-21`) to say "parts"
- [x] **2.3b** Update arch's flat part links (`:243-245`) from `./<slug>-part1.md` to directory mode: `NN-<slug>/plan-NN-<feature>-<slug>.md`

**Verify phase 2:**
- [x] **2.T1** Integration — `grep -c "^## Sub-Plan Breakdown" skills/planning/_template_plan.md` = 1
- [x] **2.T2** Integration — in `_template_arch.md`: `grep -cE "^## (Critical User Journeys|Data Model|API|System Boundaries)"` = 0 AND `grep -cE "^### (Critical User Journeys|Data Model|API Contracts|System Boundaries)"` = 4 AND `grep -c "^## Design Details"` = 1 (proves nested, not deleted)
- [x] **2.T2b** Manual — arch's `## API / Contract` renamed to `API Contracts` to match the plan template
- [x] **2.T3** Manual — `_template_arch.md` contains no `Implementation Phases` section

---

### Phase 3 — Selector prose

- [x] **3.1** Replace `skills/planning/SKILL.md:48-49` with the selector-by-the-bit prose (see above)
- [x] **3.2** Update `skills/planning/SECTIONS.md:9` — names both template files
- [x] **3.4** Update `skills/planning/FORMAT.md:5-6` — names both old template files
- [x] **3.3** Update the existing naming table at `skills/planning/SKILL.md:64` (`Master design | plan-<feature>.md`) to cover `arch-<feature>.md` — update in place, do not add a second table

**Verify phase 3:**
- [x] **3.T1** Manual — the selector never mentions feature size; it asks whether the doc carries implementation phases
- [x] **3.T2** Manual — "If unsure: use `plan`" is present

---

### Phase 4 — Downstream references

- [x] **4.1** Update `skills/planning/scaffold.sh:40` copy list to the new template names
- [x] **4.2** Update `scaffold.sh:72,80,96,140,145-146` emitted project-guide text (includes "master design" vocabulary)
- [x] **4.3** Update `skills/sdlc/SKILL.md:107,112` — "master design" → arch/parts vocabulary
- [x] **4.3b** Update `skills/sdlc/SKILL.md:135` workflow — `arch-<feature>.md (rare) | plan-<feature>.md → review`
- [x] **4.3c** **Resolve the no-sub-features case via a degenerate queue entry.** When decomposition yields zero parts, enqueue ONE entry whose artifact is `plan-<feature>.md` (`id: root`, `origin: planned`). Every existing mechanism — `awaiting_*` lifecycle, drain gate, M3 handoff, M4 replan, `/sdlc continue` — then works unchanged
- [x] **4.3c1** Rationale to record: master-level execution has **nowhere to live** in the schema — `mode`, `awaiting_phase`, `last_completed`, `handoff` are all fields on `subfeatures[]` entries (`SKILL.md:258-288`). "The master plan itself implements" would require new master-level fields, contradicting 4.3d
- [x] **4.3c2** Edit `SKILL.md:133-151` workflow diagram + `:153` outer-loop bullet — zero parts → one `root` entry, not straight to drain
- [x] **4.3c3** Edit `GRAMMAR.md:94` — awaiting is set on a sub-feature entry; `root` is one
- [x] **4.3c4** Add a `root`-entry example to the `.sdlc-state.yaml` schema block
- [x] **4.3d** `SKILL.md:264-266` — confirm **no schema change**: `master.plan` covers arch-or-plan completion, and execution state lives on the `root` entry like any other sub-feature
- [x] **4.3e** `GRAMMAR.md:39` — artifact column for the `plan` token must include `arch-<feature>.md`
- [x] **4.3f** Confirm `PHASES.md` and `EXAMPLES.md` need NO change — say so, to stop the implementer hunting
- [x] **4.4** Update repo-layout blocks: `CLAUDE.md`, root `AGENTS.md:38-39`, `README.md:59-60` (template-name lines)
- [x] **4.4b** Update **feature-plan layout** blocks — `README.md:147`, `AGENTS.md:61`, `CLAUDE.md:65` still say `plan-<feature>.md ← master design`; add the `arch-<feature>.md` line
- [x] **4.4c** Note: `report` landed first, so line numbers above may have drifted — grep, don't trust them
- [x] **4.5** Add stale-ref lint check for `_plan_sample_big|small` (mirrors the existing `_plan_sample_format.md` check at `lint.sh:49`)
> **4.6 heading-parity check — CUT.** Templates intentionally diverge (Requirements split, 5-vs-4 column tables), so a shared-headings list becomes a third hand-maintained artifact that drifts. `2.T1`-`2.T3` already pin the structure.

**Verify phase 4:**
- [x] **4.T1** Integration — `bash skills/planning/scaffold.sh $(mktemp -d)` exits 0
- [x] **4.T2** Integration — `T=$(mktemp -d); bash skills/planning/scaffold.sh $T | tee /tmp/o && grep -q "_template_plan" $T/AGENTS.md && ! grep -q "_plan_sample" $T/AGENTS.md && ! grep -q "_plan_sample" /tmp/o && test -f $T/.feature-plans/_template_arch.md` (stdout checked too — `scaffold.sh:145-146` echoes never land in the guide)
- [x] **4.T3** Integration — `bash skills/sdlc/evals/lint.sh` exits 0
- [x] **4.T4** Integration — stale-ref check FAILS when `_plan_sample_big` is reintroduced
- [x] **4.T5** Integration — `D=$(mktemp -d); CLAUDE_SKILLS_DIR=$D ./install.sh claude-code && test -f $D/planning/_template_arch.md && test -f $D/planning/_template_plan.md && ! test -e $D/planning/_plan_sample_big_feature_design.md`
- [x] **4.T6** Integration — `grep -rni "mini-design" skills/` returns zero hits (repo-wide, after Phase 3)
- [x] **4.T7** Integration — `grep -rn "_plan_sample_big\|_plan_sample_small" . --exclude-dir=.feature-plans --exclude-dir=.git --exclude=lint.sh` returns zero hits

---

### Phase 5 — Relax the line cap by load cost

> **Rationale:** the flat 200-line cap forced budget-neutral edits on `SECTIONS.md` (199/200) and
> `PHASES.md` (199/200), trading clarity for line count. This toolkit is the backbone of real
> projects — the constraint should track **context cost**, not file size.

**New rule — cap by when the file loads, not what it is:**

| Class | Files | Cap | Why |
|-------|-------|----:|-----|
| Always-loaded | `SKILL.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | **400** | Costs context on every invocation |
| On-demand companions | `FORMAT.md`, `SECTIONS.md`, `PHASES.md`, `GRAMMAR.md`, `EXAMPLES.md` | **600** | Loaded only when the phase needs it |
| Templates | `_template_*.md` | **none** | Copied, never loaded as context |

- [x] **5.1** Rewrite `skills/coding-agent-guardrails/SKILL.md:24` with the three-class table
- [x] **5.2** Update **both** `lint.sh` cap loops (#3 at `:33-42` and #15 at `:167-176`) to one per-class check
- [x] **5.2b** Enumerate the always-loaded class explicitly: every `skills/*/SKILL.md`, root `CLAUDE.md`, root `AGENTS.md` — none are covered today, so the class would otherwise have no teeth
- [x] **5.2c** Enumerate the companion class: `FORMAT.md`, `SECTIONS.md`, `PHASES.md`, `GRAMMAR.md`, `EXAMPLES.md`
- [x] **5.5** Update `scaffold.sh:105` — it emits "max **200 lines**" into every scaffolded project's guide, which would contradict the new rule
- [x] **5.6** Correct the Option B rejection in this plan's Alternatives table — "over the 200 cap" is false once the cap is 600; B still loses on mixing rules with section specs
- [x] **5.3** Exempt `_template_*.md` from the cap entirely
- [x] **5.4** Restore clarity lost to earlier budget trimming — re-add the `stateDiagram` example cut from `SECTIONS.md` § Diagrams

**Sizing check (caps chosen to fit reality with real headroom, not to force trims):**

| File | Now | Class cap | Headroom |
|------|----:|----------:|---------:|
| `skills/sdlc/SKILL.md` | 338 | 400 | 62 |
| `skills/sdlc/EXAMPLES.md` | 474 | 600 | 126 |
| `skills/sdlc/PHASES.md` | 199 | 600 | 401 |

**Verify phase 5:**
- [x] **5.T1** Integration — `bash skills/sdlc/evals/lint.sh` exits 0 against ALL current files (verify `sdlc/SKILL.md` at 348 passes the 400 cap; a 300 cap would have failed on day one)
- [x] **5.T2** Integration — pad `skills/prd/SKILL.md` (49 lines) past 400 → lint FAILS; revert
- [x] **5.T3** Integration — pad the **enumerated** `skills/planning/SECTIONS.md` to 500 → PASSES; to 700 → FAILS; revert. (A brand-new unlisted file would pass vacuously — the class must enumerate)
- [x] **5.T4** Manual — no file was padded just because the cap rose; the limit is a ceiling, not a target

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `_template_arch.md` | 1.1, 1.3, 2.2-2.4 | Rename, retitle, nest sections |
| `_template_plan.md` | 1.2, 1.4-1.5, 2.1 | Rename, retitle, Sub-Plan Breakdown |
| `skills/planning/SKILL.md` | 3.1, 3.3 | Selector + filename convention |
| `skills/planning/SECTIONS.md` | 3.2 | Template filenames |
| `skills/planning/scaffold.sh` | 4.1-4.2 | Copy list + emitted text |
| `skills/sdlc/SKILL.md`, `GRAMMAR.md` | 4.3-4.3c4 | arch vocabulary, root entry, artifact column (`PHASES.md` needs NO change — 4.3f) |
| `CLAUDE.md`, `AGENTS.md`, `README.md` | 4.4 | Repo layout |
| `skills/sdlc/evals/lint.sh` | 4.5, 5.2-5.3 | Stale-ref check, per-class caps (4.6 heading-parity check CUT — see Phase 4) |
| `skills/coding-agent-guardrails/SKILL.md` | 5.1 | Line cap by load cost |
| `skills/planning/SECTIONS.md` | 3.2, 5.4 | Template filenames; restore trimmed example |

## Cost

- 2 `git mv`, 2 H1 retitles, 1 nesting pass, 1 new section, 1 selector rewrite
- 8 reference sites + 2 new lint checks
- `sdlc` needs the `arch-` filename + parts/sub-plans vocabulary — **not** a no-op

---

## Post-implementation review (opus)

> All items above were implemented and verified before this review; findings below were applied on top.

| # | Finding | Applied? | Where |
|---|---------|:---:|-------|
| 1 | `root` entry would get **double-reviewed** — feature-level `plan → review` already reviews `plan-<feature>.md`, then the inner cycle's `plan → review` would review it again | ✅ | `SKILL.md` workflow: `root` enters the inner cycle at `implement`, never re-reviews its own plan |
| 2 | Feature-level `awaiting_phase` (E22/E27/E29/E30/E31/E33/E37) has no schema home **before** decomposition — the `root` entry as originally scoped (created only on zero-parts decompose) doesn't exist yet during the master PRD/plan phases | ✅ | `root` now created at **feature creation (M1)**, not at decomposition; an `arch` decomposition into ≥1 parts retires it |
| 3 | `PHASES.md` M4 "supersede, keep `NN`" doesn't define behavior for `root` (no `NN`) | ✅ | One-line carve-out added to `PHASES.md` M4 table |
| 4 | `_template_arch.md` retitled `# Arch:` but body still says "design" in several places (parts tracker label, rollout flag names) | ✅ | Reworded to "arch" throughout the file |
| 5 | `cases.md` header/status say "E1-E33" but the table runs to E38; `evals/README.md` repeats the stale range | ✅ | Both corrected to E1-E38 |
| 6 | New eval cases needed for arch/plan selection, zero-parts `root`, and arch-with-phases | ✅ | E39-E46 added to `cases.md` (see below) |
| 7 | `_template_arch.md`/`_template_plan.md` frontmatter PRD path uses flat mode, not directory mode | ❌ rejected | Reviewer flagged this as pre-existing, not introduced by this restructure — out of scope |
| 8 | Root `AGENTS.md` skills table/repo-layout is stale vs `CLAUDE.md` (missing `coding`, `android-coding`, `sdlc`, `GRAMMAR.md`) | ❌ rejected | Pre-existing drift unrelated to the arch/plan restructure or `report` skill — out of scope for this plan |
| 9 | Companion-class lint enumeration is a fixed list, not `find`-based — a new companion file passes vacuously | ❌ rejected | By design (plan `5.T3`); a `find`-based rule can't distinguish a companion from any other `.md` file by name alone |
| 10 | Bare code spans (not markdown links) for `_template_arch.md`/`_template_plan.md` in `SKILL.md`'s "Which template?" section | ✅ | Converted to links |
