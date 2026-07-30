# Mini-Design: Feature Directory Grouping

> Restructure `.feature-plans/` to group related docs (prd, plan, sub-plans, screenshots) under a feature directory that moves atomically through pending → wip → done.

**Issue:** upgrade-to-sdlc-nfeaturegrouping-jul26
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26`
**Status:** Pending
**Parent design:** `./plan-sdlc-skill-feature-grouping.md`

**Reference files:**
- Planning skill: `skills/planning/SKILL.md`
- PRD skill: `skills/prd/SKILL.md`
- Scaffold script: `skills/planning/scaffold.sh`

---

## Problem

- Related docs for a feature (prd, plan, sub-plans) scatter across `pending/`, `wip/`, `done/`
- Hard to see full feature context at a glance
- Moving feature through states requires moving multiple individual files

## Out of Scope

- SDLC orchestration logic (handled in 03-sdlc-orchestration.md)
- Screenshot lifecycle (handled in 02-format-enforcement.md)
- Config file schema (handled in 03-sdlc-orchestration.md)

## Concept

- Feature docs live in `<state>/<feature-slug>/` directory
- Directory moves atomically: `pending/auth-flow/` → `wip/auth-flow/` → `done/auth-flow/`
- Flat-file mode remains supported for backward compat

## Requirements

| # | Requirement |
|---|-------------|
| 1 | All related docs for a feature live in one directory |
| 2 | Directory naming: `<feature-slug>/` (lowercase, hyphenated) |
| 3 | Doc filenames carry the feature name — searchable without directory context |
| 4 | Feature root: `.sdlc-state.yaml`, `prd-<feature>.md`, `plan-<feature>.md` |
| 5 | Sub-features nest as `NN-<slug>/`, containing `plan-<NN>-<feature>-<subfeature>.md` |
| 6 | Screenshots live inside the sub-feature that produced them |
| 7 | Simple features skip sub-feature dirs — `plan-<feature>.md` at feature root |
| 8 | Backward compat: flat files (`auth-flow.md`) still work; resume detects which mode |
| 9 | **`scaffold.sh` runs without error** — currently broken, must be fixed here |

---

## Research

### scaffold.sh is BROKEN on main — pre-existing bug

- **File:** `skills/planning/scaffold.sh:27` — `for f in _plan_sample_format.md AGENTS.md; do`
- **Problem:** `_plan_sample_format.md` no longer exists — split into `_plan_sample_big_feature_design.md` + `_plan_sample_small_feature_bugfix.md`
- **Effect:** `cp` fails → `set -euo pipefail` (line 10) aborts the script mid-run
- **Reproduced:** `bash skills/planning/scaffold.sh /tmp/x` → `cp: cannot stat '_plan_sample_format.md'`
- **Risk:** HIGH — scaffolding a new project fails today; blocks the whole "start a project" path

### Stale `_plan_sample_format.md` references elsewhere

- **Files:** `skills/planning/scaffold.sh:59,101` (emitted text + final echo), `skills/planning/AGENTS.md:39`, `CLAUDE.md:35`, `AGENTS.md:34`, `README.md:54`
- **Risk:** MEDIUM — point readers at a file that doesn't exist

### scaffold.sh does more than create directories

- **File:** `skills/planning/scaffold.sh:27-97`
- **Actual behavior:** creates dirs, copies templates + AGENTS.md, **generates project-root `AGENTS.md` + `CLAUDE.md`**
- **Gap:** the generated guide (lines 50-88) teaches flat `pending/<slug>.md` mode — this is the text downstream project agents actually read
- **Risk:** HIGH — updating only the vibekit-side skill docs leaves every scaffolded project on the old convention

### Template references in planning SKILL.md

- **File:** `skills/planning/SKILL.md:43`
- **Current:** instructs user to create `pending/<slug>.md`
- **Risk:** LOW — update to directory mode

---

## Architecture

```
scaffold.sh
    │
    ├── (FIX) copy the two real templates, not _plan_sample_format.md
    ├── (FIX) stale refs in emitted text + final echo
    ├── (NEW) .gitkeep in pending/wip/done
    └── (UPDATE) generated project AGENTS.md/CLAUDE.md → directory mode

skills/planning/SKILL.md
    │
    └── (UPDATE) how-to-use section
         "create pending/<feature>/plan-<feature>.md"
         (backward compat: "or pending/<slug>.md for single-file features")

skills/prd/SKILL.md
    │
    └── (UPDATE) workflow section
         "create pending/<feature>/prd-<feature>.md"
```

---

## Design Details

### Critical User Journeys (CUJs)

#### CUJ 1 — New feature with PRD + plan

```
User invokes /sdlc auth-flow
  → Agent creates .feature-plans/pending/auth-flow/
  → Agent writes auth-flow/prd-auth-flow.md
  → Agent writes auth-flow/plan-auth-flow.md
  → Agent writes auth-flow/01-data-layer/plan-auth-flow-data-layer.md
  → Work begins
  → Agent moves auth-flow/ to wip/
  → Work completes
  → Agent moves auth-flow/ to done/
```

- **Error path:** directory already exists → prompt user to resume or rename
- **Edge case:** single-file feature → create `pending/small-fix.md` (flat mode)

#### CUJ 2 — Resume existing feature

```
User invokes /sdlc auth-flow
  → Agent detects .feature-plans/wip/auth-flow/ exists
  → Agent continues from last checkpoint
  → No directory creation
```

### Key Decisions

#### Decision 1: Directory naming convention

- **Decision:** `<feature-slug>/` (lowercase, hyphenated, no prefix)
- **Rationale:** Simpler than `feature-auth-flow/`; consistent with branch naming
- **Where:** `skills/planning/SKILL.md:43` — update how-to-use section

#### Decision 2: Feature name AND NN embedded in every filename

- **Decision:** `prd-<feature>.md`, `plan-<feature>.md`, `plan-<NN>-<feature>-<subfeature>.md`
- **Rationale:** Fuzzy-find by feature name surfaces every related doc; `NN` makes execution order visible in flat search results and editor tabs, where the parent directory isn't shown — `plan.md` × 12 features is unusable
- **Where:** `skills/planning/SKILL.md`, `skills/prd/SKILL.md` — document naming convention

```
❌ auth-flow/plan.md                    → 12 tabs all named "plan.md"
❌ 02-api/plan-auth-flow-api.md         → order invisible in flat search
✅ 02-api/plan-02-auth-flow-api.md      → unambiguous + ordered everywhere
```

- `NN` is assigned once and **never renumbered** — it is an identifier, not a position
- New sub-features always append; a bug bundle discovered after `03` becomes `04`, never `02.5`
- Renumbering would break `spawned_from` refs in `.sdlc-state.yaml` and git history

#### Decision 3: Backward compatibility with flat files

- **Decision:** Support both `pending/<feature>/` (directory) and `pending/<slug>.md` (flat)
- **Rationale:** Existing projects have flat files; forced migration is disruptive
- **Where:** `skills/planning/SKILL.md:43-52` — document both modes

**Detection rule (used on resume):**

```
given <name> under pending|wip|done:
  <name>/ is a directory  → directory mode; read <name>/.sdlc-state.yaml
  <name>.md is a file     → flat mode; no state file, no sub-features
  both exist              → prefer directory; warn about the stray flat file
```

- New features always use directory mode; flat mode is read-only compatibility

#### Decision 4: Fix scaffold.sh as part of this sub-feature

- **Decision:** Repair the broken template copy here rather than filing it separately
- **Rationale:** Every other item in this sub-feature edits `scaffold.sh`; leaving it broken means the phase-2 verification cannot run at all
- **Where:** `skills/planning/scaffold.sh:27,59,101`

---

## Files to Modify

| File | Change |
|------|--------|
| `skills/planning/scaffold.sh` | **Fix broken template copy**; stale refs; `.gitkeep`; regenerate project guide for directory mode |
| `skills/planning/SKILL.md` | How-to-use for directory mode + naming convention + backward compat |
| `skills/planning/AGENTS.md` | Fix stale `_plan_sample_format.md` ref (line 39) |
| `skills/prd/SKILL.md` | Workflow section for directory mode |
| `CLAUDE.md` | Repo layout + stale template ref (line 35) |
| `AGENTS.md` | Stale template ref (line 34) |
| `README.md` | Stale template ref (line 54) |

## Risks / Open Questions

| # | Question | Notes |
|---|----------|-------|
| 1 | **Mixed flat + directory?** | Both work; detection rule in Decision 3; new features use directory mode |
| 2 | **Git tracks empty directories?** | No; `.gitkeep` files ensure structure persists |
| 3 | **Scaffolded projects already on old text?** | Re-running `scaffold.sh` overwrites the generated guide; no auto-migration |

---

## Implementation Phases

### Phase 0 — Repair broken scaffold.sh

- [x] **0.1** Fix `scaffold.sh:27` — copy `_plan_sample_big_feature_design.md` + `_plan_sample_small_feature_bugfix.md` (not `_plan_sample_format.md`)
- [x] **0.2** Fix stale `_plan_sample_format.md` refs in `scaffold.sh:59` (emitted text) and `:101` (final echo)
- [x] **0.3** Fix stale refs in `skills/planning/AGENTS.md:39`, `CLAUDE.md:35`, `AGENTS.md:34`, `README.md:54`
- [x] **0.4** Fix stale lowercase `skill.md` refs (`README.md:48-57,69,88`; root `AGENTS.md` repo-layout + "Adding a new skill") — renamed to `SKILL.md` in commit c992b56
- [x] **0.5** Fix `CLAUDE.md:51,54` — documents `./install.sh cursor [target-dir]` but the real signature is `[skill-name] [target-dir]`

**Verify phase 0:**
- [x] **0.T1** Integration — `bash skills/planning/scaffold.sh /tmp/scaffold-test` exits 0
- [x] **0.T2** Integration — Both template files land in `/tmp/scaffold-test/.feature-plans/`
- [x] **0.T3** Integration — `grep -rn "_plan_sample_format.md" .` returns zero hits
- [x] **0.T4** Integration — `grep -rn "skill\.md" README.md AGENTS.md` returns zero hits
- [x] **0.T5** Manual — `./install.sh cursor all /tmp/x` matches the documented signature

---

### Phase 1 — Update skill docs for directory mode

- [x] **1.1** Update `skills/planning/SKILL.md:43-52` how-to-use section
  - Primary: `pending/<feature>/plan-<feature>.md`
  - Sub-features: `pending/<feature>/NN-<sub>/plan-<NN>-<feature>-<sub>.md`
  - Secondary (backward compat): `pending/<slug>.md`
- [x] **1.2** Add naming-convention table + `NN` never-renumbered rule to `skills/planning/SKILL.md`
- [x] **1.3** Update `skills/prd/SKILL.md` workflow — PRD at `pending/<feature>/prd-<feature>.md`
- [x] **1.4** Add flat-vs-directory detection rule (Decision 3) to `skills/planning/SKILL.md`
- [x] **1.5** Update `CLAUDE.md` repo layout diagram

**Verify phase 1:**
- [x] **1.T1** Manual — Directory mode is primary; naming table matches master design exactly
- [x] **1.T2** Manual — Detection rule covers directory / flat / both-exist cases
- [x] **1.T3** Manual — No doc still shows bare `plan.md` or `prd.md` as the convention

---

### Phase 2 — Scaffold: directory mode + gitkeep

- [x] **2.1** Add `.gitkeep` to `pending/`, `wip/`, `done/` in `scaffold.sh`
- [x] **2.2** Rewrite the **generated project AGENTS.md/CLAUDE.md** (`scaffold.sh:50-88`) for directory mode + naming convention
- [x] **2.3** Update scaffold echo messages + final "Next:" line to directory mode
- [x] **2.4** Add example directory tree to scaffold output

**Verify phase 2:**
- [x] **2.T1** Integration — Scaffold a temp dir; `.gitkeep` present in all three state dirs
- [x] **2.T2** Integration — Generated project `AGENTS.md` describes `pending/<feature>/plan-<feature>.md`, not flat mode
- [x] **2.T3** Integration — `grep -c "pending/<slug>.md" <generated AGENTS.md>` shows it only as backward-compat, not primary

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `skills/planning/scaffold.sh` | 0.1-0.2, 2.1-2.4 | Fix broken copy; gitkeep; regenerate project guide |
| `skills/planning/AGENTS.md` | 0.3 | Stale template ref |
| `AGENTS.md`, `README.md` | 0.3 | Stale template refs |
| `skills/planning/SKILL.md` | 1.1-1.2, 1.4 | Directory mode, naming table, detection rule |
| `skills/prd/SKILL.md` | 1.3 | Directory mode in workflow |
| `CLAUDE.md` | 0.3, 1.5 | Stale ref + repo layout |
