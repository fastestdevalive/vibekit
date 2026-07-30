<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# Mini-Design: SDLC Orchestration Skill

> New `sdlc` skill that decomposes a feature into sub-features and runs each through PRD → Plan → Review → Implement → Verify → Review, with a pluggable reviewer model.

**Issue:** upgrade-to-sdlc-nfeaturegrouping-jul26
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26`
**Status:** Pending
**Parent design:** `./plan-sdlc-skill-feature-grouping.md`

**Reference files:**
- Planning skill: `skills/planning/SKILL.md`
- PRD skill: `skills/prd/SKILL.md`
- Base guardrails: `skills/coding-agent-guardrails/SKILL.md` _(renamed in 04 Phase 0 — runs first)_
- Claude adapter: `adapters/claude-code/install.sh:29-42`

---

## Problem

- User manually invokes each SDLC step: PRD → plan → opus review → adjust → implement → verify → review
- Reviewer model (opus) hardcoded in user workflow — not configurable
- No skill automates the chain, and none models the sub-feature loop the master design requires
- Different CLIs have different "smart" models — need a pluggable resolver

## Out of Scope

- Cursor/Gemini adapters for SDLC skill (future phase)
- Execution modes M1-M8 + evals — owned by `05-execution-modes.md`
- Format/checklist/boundary rules — owned by `02-format-enforcement.md`
- CI/CD integration; auto-PR creation; multi-repo orchestration

## Concept

- New `skills/sdlc/` skill orchestrates the chain
- Feature decomposes into sub-features; each sub-feature runs its own inner cycle
- Outer loop drains the sub-feature queue; bugs found in verification re-enter it as a new sub-feature
- Reviewer model configurable; skill is additive — prd/planning still work standalone

## Requirements

| # | Requirement |
|---|-------------|
| 1 | New `sdlc` skill: `SKILL.md` + `PHASES.md` (linked from SKILL.md) |
| 2 | Triggers: `/sdlc`, "run full sdlc", "sdlc workflow" |
| 3 | Subcommands: `status`, `list`, `add`, `bugs`, `prd`, `handoff`, `replan`, `park` — all 8 registered |
| 4 | Master PRD + master design written once at feature level |
| 5 | Feature decomposes into `NN-` sub-features; each gets its own plan (+ optional PRD) |
| 6 | Outer loop drains sub-feature queue until empty |
| 7 | Bugs from verification cluster into ONE new sub-feature — never one-plan-per-bug |
| 8 | Reviewer model from `.vibekit.yaml` → `sdlc.reviewer.model`; `${CLI_DEFAULT}` sentinel supported |
| 9 | Max review iterations (default 3) with escalation to user |
| 10 | Screenshots transient by default; cleanup confirmed by user before deletion |
| 11 | Directory lifecycle: pending → wip → done, moving the whole feature dir |
| 12 | State persistence via `.sdlc-state.yaml` with `subfeatures[]` for resume |
| 13 | Subagents spawn via a **runner abstraction** — in-harness or delegated to a meta-harness |
| 14 | **Default is in-harness for every role**; meta-harness requires explicit config, never inferred |
| 15 | Meta-harness unavailable → fall back to in-harness with a warning, never hard-fail |
| 16 | Runner block is **generated from the initial prompt** + detection, then shown for approval |

---

## Research

### Existing skill structure

- **File:** `skills/planning/SKILL.md:1-12`
- **Pattern:** YAML frontmatter (`name`, `description`, `version`, `triggers`, `globs`) → when-to-use → how-to-use
- **Risk:** LOW — follow the same shape

### Claude Code adapter — copies whole skill dir

- **File:** `adapters/claude-code/install.sh:29-34` — `for f in "$src"/*; do cp -R "$f" "$dest/"`
- **File:** `adapters/claude-code/install.sh:38` — `for d in "$SKILLS_SRC"/*/` — skills are discovered by **glob, not a list**
- **Consequence:** no "add to install list" step exists or is needed; a new `skills/sdlc/` dir is picked up automatically
- **Consequence:** every file in the skill dir ships to `~/.claude/skills/<name>/` — subdirectories and maintainer docs included
- **Risk:** MEDIUM — see Decision 7 (exclude eval fixtures from install)

### Subagent spawning varies by CLI

- **Claude Code:** `Agent` tool with `model` parameter
- **Cursor:** composer with model selection
- **Gemini:** `gemini` with model flag
- **Risk:** MEDIUM — only Claude Code is in V1 scope; sentinel keeps config portable

### In-harness subagents share the caller's working directory

- **Behavior:** an in-harness subagent writes to the same worktree as the parent session
- **Safe:** read-only agents (reviewer) — no write contention
- **Unsafe:** two implementers on the same worktree — concurrent edits to the same files
- **Also:** in-harness agents die with the parent session — no durability across a crash or context exhaustion
- **Risk:** HIGH for parallel implementation; LOW for the review loop V1 actually uses

### Meta-harness options available to this user

| Harness | What it provides | Detection signal |
|---------|-----------------|------------------|
| `agent-orchestrator` | Durable Claude Code/Codex/OpenCode sessions, per-agent isolation, feedback routing | `ao` on PATH, or `.agent-orchestrator/` present |
| `vibe-station` | Project/worktree management, per-worktree agent sessions | `.vibe-station/` in path ancestry |
| custom | Anything with a spawn command | explicit config only |

- **Risk:** MEDIUM — exact CLI surface differs per harness; the skill must not hardcode one

---

## Architecture

```
/sdlc <feature>
      │
      ▼
┌──────────────────────────────┐
│ read .vibekit.yaml           │  reviewer.model, max_iterations,
│ (defaults if absent)         │  screenshots.policy
└──────────────┬───────────────┘
               ▼
┌──────────────────────────────┐
│ FEATURE LEVEL (once)         │
│  prd-<feature>.md   → review │
│  plan-<feature>.md  → review │
│  decompose → NN- queue       │
└──────────────┬───────────────┘
               ▼
      ┌────────────────┐
      │ queue empty?   │◀─────────────────┐
      └───┬────────┬───┘                  │
       no │        │ yes → move to done/  │
          ▼                               │
┌──────────────────────────────┐          │
│ SUB-FEATURE CYCLE            │          │
│  prd?  → review              │          │
│  plan  → review              │          │
│  implement (mark [x])        │          │
│  verify (tests + device)     │          │
│  final review                │          │
│  cleanup + commit            │          │
└──────────────┬───────────────┘          │
               │ bugs found → cluster ────┘
               │ into new NN- sub-feature
               └──────────────────────────┘
```

---

## Design Details

### Critical User Journeys (CUJs)

#### CUJ 1 — Full SDLC, large feature

```
User: /sdlc auth-flow
  → size? → large
  → create pending/auth-flow/ + .sdlc-state.yaml
  → /prd → auth-flow/prd-auth-flow.md → review → incorporate
  → /planning → auth-flow/plan-auth-flow.md → review → incorporate
  → decompose → queue: [01-data-layer, 02-api, 03-ui]
  → move auth-flow/ to wip/
  → for each sub-feature:
       → plan-NN-auth-flow-<sub>.md → review → implement → verify → review
       → cleanup screenshots → commit
  → queue empty → move auth-flow/ to done/ → prompt: create PR?
```

- **Error path:** reviewer unavailable → warn, continue without review
- **Edge case:** user cancels mid-cycle → state preserved in `wip/`

#### CUJ 2 — Small feature, no decomposition

```
User: /sdlc fix-login-button
  → size? → small
  → skip PRD; skip decomposition
  → plan-fix-login-button.md at feature root → review → implement → verify
  → commit → done/
```

#### CUJ 3 — Verification finds bugs

```
Verifying 02-api → 4 bugs found, 2 share a root cause
  → cluster into ≤2 sub-features (NOT 4)
  → write 04-fix-api-errors/ with origin: bug-bundle, spawned_from: 02-api
  → append to queue → outer loop continues
```

#### CUJ 4 — Resume

```
User: /sdlc auth-flow
  → wip/auth-flow/.sdlc-state.yaml exists
  → read current_subfeature + last_completed
  → restate next unchecked item, then continue
  → never re-run items already marked [x]
```

### Data Model

| Entity | Field | Type | Constraints | Notes |
|--------|-------|------|-------------|-------|
| `.vibekit.yaml` | `sdlc.runner.mode` | enum | optional | `auto`\|`in-harness`\|`meta-harness`; default `auto` |
| `.vibekit.yaml` | `sdlc.runner.meta_harness` | enum | optional | `null` (default) \| `agent-orchestrator` \| `vibe-station` \| `custom` |
| `.vibekit.yaml` | `sdlc.runner.roles.<role>` | enum | optional | Per-role `in-harness`\|`meta-harness`; all default `in-harness` |
| `.vibekit.yaml` | `sdlc.runner.spawn_command` | string | required if `custom` | Template with `{worktree}` `{model}` `{prompt}` |
| `.vibekit.yaml` | `sdlc.reviewer.model` | string | optional | Default: `opus` |
| `.vibekit.yaml` | `sdlc.reviewer.max_iterations` | int | optional | Default: `3` |
| `.vibekit.yaml` | `sdlc.reviewer.prompt` | string | optional | Extra review instructions |
| `.vibekit.yaml` | `screenshots.policy` | enum | `transient`\|`permanent` | Default: `transient` |
| `.vibekit.yaml` | `screenshots.confirm_cleanup` | bool | optional | Default: `true` |
| `.vibekit.yaml` | `setup.commands` | string[] | optional | Free-form project bootstrap (see Decision 6) |
| `.sdlc-state.yaml` | `feature` | string | required | Feature slug |
| `.sdlc-state.yaml` | `worktree` | path | required | Guards against wrong-worktree writes |
| `.sdlc-state.yaml` | `master.prd` / `master.plan` | enum | required | `complete`\|`skipped`\|`pending` |
| `.sdlc-state.yaml` | `current_subfeature` | string | required | Resume anchor |
| `.sdlc-state.yaml` | `subfeatures[]` | list | required | See schema below |

### API Contracts

```yaml
# .vibekit.yaml — full V1 schema
sdlc:
  runner:                    # canonical schema — see Decision 10
    mode: auto               # auto | meta-harness | in-harness
    meta_harness: null       # null (default) | agent-orchestrator | vibe-station | custom
    roles:
      implementer: in-harness
  reviewer:
    model: opus              # explicit name, or ${CLI_DEFAULT}
    max_iterations: 3
    prompt: |                # optional, appended to review request
      Flag missing test coverage and undefined cross-layer contracts.
  setup:
    commands:                # optional, free-form; run before implementation
      - git submodule update --init --recursive
  device:
    ask_before_access: true  # shared-device protocol

screenshots:
  policy: transient          # DEFAULT — never committed unless changed
  confirm_cleanup: true
```

```yaml
# .sdlc-state.yaml — at feature root
feature: auth-flow
worktree: /home/gb/code/proj/worktrees/wt-1
created: 2026-07-25T10:00:00Z

master:
  prd: complete
  plan: complete

current_subfeature: 03-fix-nav-regressions

subfeatures:
  - id: 01-data-layer
    origin: planned          # planned|bug-bundle|requirement-change|refinement
    mode: done               # planning|implementing|verifying|parked|handoff|done
    commit: a1b2c3d
  - id: 03-fix-nav-regressions
    origin: bug-bundle
    spawned_from: 02-api
    mode: implementing
    last_completed: "2.3"    # checklist id — resume anchor
```

- Per-phase status is NOT duplicated in state — the plan checklist is the source of truth (see Decision 8)

### Key Decisions

#### Decision 1: Reviewer model configuration

- **Decision:** `.vibekit.yaml` → `sdlc.reviewer.model`, with `${CLI_DEFAULT}` sentinel
- **Rationale:** User's ask — opus is Claude-specific; other CLIs have their own best model
- **Where:** `skills/sdlc/SKILL.md` — config section

| Sentinel | Claude Code | Cursor | Gemini CLI |
|----------|-------------|--------|------------|
| `${CLI_DEFAULT}` | `opus` | `claude-sonnet` | `gemini-2.5-pro` |

- Unknown/unresolvable model → warn + fall back to the CLI's default agent, never hard-fail

#### Decision 2: Feature size is asked, not inferred

- **Decision:** Agent asks "large feature (PRD needed) or small fix?"
- **Rationale:** Heuristics on feature size are unreliable; user knows
- **Where:** `skills/sdlc/PHASES.md` — phase 1

#### Decision 3: Decomposition boundary

- **Decision:** One sub-feature = one plan = one review-implement-verify cycle = one commit
- **Rationale:** Gives a natural context boundary for handoff to a fresh/cheaper agent
- **Where:** `skills/sdlc/SKILL.md` — decomposition section

#### Decision 4: Bug clustering

- **Decision:** Wait for a full verification pass; cluster bugs by root cause into one sub-feature
- **Rationale:** Prevents `plan-1.1`, `plan-1.2`, `plan-1.3` sprawl
- **Where:** `skills/sdlc/PHASES.md` — verification phase

#### Decision 5: Max review iterations with escalation

- **Decision:** 3 iterations, then escalate
- **Rationale:** Prevents infinite review loops; user decides whether to accept or pause
- **Where:** `skills/sdlc/SKILL.md` config; `skills/sdlc/PHASES.md` escalation flow

```
iteration 1 → feedback → incorporate
iteration 2 → feedback → incorporate
iteration 3 → still failing → ESCALATE
  → "Reviewer rejected 3×. (1) continue anyway (2) pause for manual review"
```

#### Decision 6: Project setup is free-form commands, not typed fields

- **Decision:** `setup.commands: string[]` instead of `submodule_init` / `copy_gitignored`
- **Rationale:** Earlier draft baked Android specifics (`local.properties`, `google-services.json`) into a generic schema; a command list covers every project type without the skill knowing any of them
- **Where:** `skills/sdlc/SKILL.md` — config schema

#### Decision 7: Exclude non-shipping files from adapter install

- **Decision:** Adapter skips `evals/` and `CONTRIBUTING.md` when copying a skill dir
- **Rationale:** `install.sh:29-34` copies every entry in the skill dir; eval fixtures would ship into every user's `~/.claude/skills/sdlc/`
- **Where:** `adapters/claude-code/install.sh:29` — skip-list guard

```bash
for f in "$src"/*; do
  case "$(basename "$f")" in evals|CONTRIBUTING.md) continue ;; esac
  cp -R "$f" "$dest/"
done
```

#### Decision 10: Runner abstraction — in-harness vs meta-harness

- **Decision:** All subagent spawning goes through a `runner` config. **Default: everything in-harness.** `mode: auto` detects a meta-harness and *suggests* it — it never delegates without explicit config.
- **Rationale:** Opting into a different execution substrate changes where files are written and which session owns them — too consequential to infer from a directory path. No config must always mean in-harness.
- **Generated, not hand-written:** `/sdlc` writes the runner block from the initial prompt + detection, then shows it for approval
- **Where:** `skills/sdlc/SKILL.md` config; `skills/sdlc/PHASES.md` spawn rules

```yaml
sdlc:
  runner:
    mode: auto                  # auto | meta-harness | in-harness
    meta_harness: null          # null = none; agent-orchestrator | vibe-station | custom
    roles:                      # per-role override; defaults shown
      planner:     in-harness   # interactive — delegating breaks the iteration loop
      reviewer:    in-harness   # read-only, short-lived
      implementer: in-harness   # → meta-harness once one is configured
      verifier:    in-harness   # needs the parent session's device context
    # only for meta_harness: custom
    spawn_command: "<cmd> --cwd {worktree} --model {model} --prompt-file {prompt}"
```

**Per-role routing — "does it write?" is the wrong axis; interactivity and isolation are:**

| Role | Writes | Interactive | Needs isolation | Default | Why |
|------|--------|:----------:|:---------------:|---------|-----|
| **Planner** | plan/PRD markdown | **Yes** | No | in-harness | You iterate on the doc; a detached agent breaks the loop |
| **Reviewer** | nothing | No | No | in-harness | Read-only, short-lived; model is already configurable in-harness |
| **Implementer** | source | No | **Yes** | in-harness → meta-harness when configured | Long-running, isolatable, survives session death |
| **Verifier** | nothing (device side effects) | No | No | in-harness | Must share the parent's device/emulator context |

- Only the **implementer** benefits from delegation — the other three are actively worse detached
- Parallel sub-features (future phase) would require `implementer: meta-harness`
- `roles.implementer: in-harness` = never delegate anything, in one line

**Placeholders in `spawn_command`:** `{worktree}` `{model}` `{prompt}` `{prompt_file}` `{feature}` `{subfeature}`

**Fallback chain:**

```
mode: auto  (default)
  → everything in-harness
  → if a harness is detected, print ONCE:
      "vibe-station detected — set runner.meta_harness to delegate implementers"
  → never delegates on detection alone
mode: meta-harness
  → use it for roles marked meta-harness
  → not detected → WARN + fall back to in-harness, continue (never hard-fail)
mode: in-harness
  → always in-harness, even if a harness exists; ignores roles overrides
```

- V1 spawns **sequentially**; the routing table matters mainly for parallel sub-features (a later phase) and for delegated implementation today
- The skill never shells out to an unrecognized harness — `custom` requires an explicit `spawn_command`

#### Decision 11: Handoff target follows the runner config

- **Decision:** `/sdlc handoff` reports the handoff summary *and* the spawn command for the configured runner
- **Rationale:** M3 (05-execution-modes) is the top real-world deviation (324 history hits); the handoff should be one paste, not a manual translation
- **Where:** `skills/sdlc/PHASES.md` — handoff section

```
meta-harness present  → prints: ao spawn --cwd <worktree> --prompt-file <handoff.md>
none                  → prints: the prompt to paste into a fresh session / other CLI
```

#### Decision 12: Commit carve-out for `.feature-plans/`

- **Decision:** Plan/state files under `.feature-plans/` are committed automatically at phase boundaries. **Source code is never committed without explicit permission.**
- **Rationale:** Resume-in-another-session (164 history hits) requires committed checklist state — but `coding-agent-guardrails` forbids unattended commits. Without a carve-out the two rules contradict and every mode transition stalls on a prompt.
- **Where:** `skills/sdlc/PHASES.md` — commit rules; `coding-agent-guardrails/SKILL.md` — add the exception

| Path | Commit without asking? |
|------|:---:|
| `.feature-plans/**` (plans, state, checklist) | ✅ yes |
| Source, config, tests, everything else | ❌ always ask |

- Auto-commits use a fixed prefix so they're easy to squash: `chore(sdlc): <feature>/<NN> <phase>`
- Directory lifecycle moves (pending→wip→done, park) are committed as part of this carve-out — an uncommitted park is invisible to the next session

#### Decision 13: Handoff return path

- **Decision:** A delegated sub-feature returns through an explicit verify step; the parent never trusts the delegate's `[x]` marks
- **Rationale:** Delegation is the #1 workflow (324 hits) but nothing specified who closes the loop; `handoff.target` was written and never read
- **Where:** `skills/sdlc/PHASES.md` — handoff section

```
delegate reports done
  → parent re-runs the plan's verify items (does NOT trust [x] marks)
     pass → mode: handoff → done; commit
     fail → cluster failures into a bug-bundle sub-feature (M5)
  → state records: returned_at, verified_by
```

**Canonical delegate prompt (PHASES.md must ship this verbatim):**

```
Implement <plan-path> fully.
- Mark each checklist item [x] as you complete it, in the plan file.
- Do NOT edit .sdlc-state.yaml — the orchestrator owns it.
- Do NOT commit source. Commit only the plan file's checklist updates.
- Stop and report if a step is ambiguous rather than guessing.
Start at <next-item>.
```

#### Decision 8: Checklist wins over state file

- **Decision:** State tracks identity/mode/anchor; the plan checklist tracks progress. On conflict, checklist wins.
- **Rationale:** Two sources of progress truth guarantees drift; the checklist is what the implementer actually edits
- **Where:** `skills/sdlc/PHASES.md` — resume rules (eval E13 asserts this)

#### Decision 9: Config discovery — project file, then defaults

- **Decision:** `.vibekit.yaml` at repo root → hardcoded defaults in SKILL.md. No global tier in V1.
- **Rationale:** A global config that silently changes behavior across repos is hard to debug for one saved keystroke
- **Where:** `skills/sdlc/SKILL.md` — config section

---

## Files to Modify

| File | Change |
|------|--------|
| `skills/sdlc/SKILL.md` | New — orchestration, config schema, decomposition, subcommands |
| `skills/sdlc/PHASES.md` | New — per-phase agent instructions, reviewer + resume + cleanup rules |
| `skills/sdlc/EXAMPLES.md` | New — 7 worked usage examples with verbatim prompts |
| `adapters/claude-code/install.sh` | Skip `evals/` when copying skill dirs |
| `.vibekit.yaml.example` | Add `sdlc:` block (file created in 02 Phase 4.1) |
| `CLAUDE.md`, `README.md` | Add `sdlc` to skills tables |

## Risks / Open Questions

| # | Question | Notes |
|---|----------|-------|
| 1 | **Reviewer model unavailable?** | Warn and continue — review is an enhancement, not a gate |
| 2 | **Feature size detection?** | Ask user; no heuristics |
| 3 | **Parallel sub-features?** | V1 sequential; parallel needs conflict handling |
| 4 | **Per-phase reviewer prompts?** | V1 single prompt; per-phase later |
| 5 | **Wrong-worktree writes (258 history hits)** | `worktree:` in state; agent verifies cwd before writing |
| 6 | **Rollback on failed impl?** | `git restore` + resume from `last_completed`; documented, not automated |

---

## Implementation Phases

> **Runs after 04 Phase 0** (guardrails rename) so SKILL.md text references the final skill name.
> **Runs after 01 + 02** (directory + format rules) so it can reference the settled conventions.

### Phase 1 — Create sdlc skill: core orchestration

- [x] **1.1** Create `skills/sdlc/SKILL.md` frontmatter (`globs: [".feature-plans/**", ".vibekit.yaml"]`) + links to `PHASES.md` and `EXAMPLES.md` (`name`, `description`, `version`, `triggers`, `globs`)
- [x] **1.2** Add config schema section (reviewer, setup.commands, device, screenshots) + defaults-when-absent
- [x] **1.3** Add feature→sub-feature decomposition section (origins, one-cycle-per-sub-feature)
- [x] **1.4** Add workflow section: feature level once, then outer queue loop
- [x] **1.5** Register ALL 8 subcommands with expected output (must match `EXAMPLES-draft-sdlc.md` exactly):

| Command | Action | Output |
|---------|--------|--------|
| `/sdlc <feature>` | Start or resume | Restates phase + next unchecked item |
| `/sdlc status` | Current state | Feature, sub-feature, mode, `[x]`/`[ ]` counts, next item |
| `/sdlc list` | All features | Table: feature, state dir, sub-feature count, parked_reason |
| `/sdlc add <name>` | Append sub-feature | New `NN-` dir + queue entry |
| `/sdlc bugs` | Cluster bugs | Proposed grouping, waits for approval |
| `/sdlc prd <feature>` | PRD-only mode | Iterates PRD; does NOT advance to plan |
| `/sdlc handoff <sub>` | Prep delegation | Self-containment report + paste-ready prompt |
| `/sdlc replan <sub>` | Supersede plan | Validity check first, then supersede if needed |
| `/sdlc park <feature>` | Park to pending/ | Moves dir, records `parked_reason` |
- [x] **1.6** Add `.sdlc-state.yaml` schema with `subfeatures[]`, `worktree`, `last_completed`
- [x] **1.7** Add runner config: modes, per-role routing table, detection-suggests-not-delegates, fallback chain
- [x] **1.8** Document runner-block generation from the initial prompt (shown for approval, not silent)

**Verify phase 1:**
- [x] **1.T1** Manual — SKILL.md describes the outer loop, not a single linear pass
- [x] **1.T2** Manual — State schema matches master design + 05's `mode`/`last_completed` fields exactly
- [x] **1.T3** Manual — All four subcommands documented with expected output
- [x] **1.T4** Manual — Routing table states which agent roles go where, and why

---

### Phase 2 — Create sdlc PHASES.md: per-phase behavior

- [x] **2.1** Reviewer invocation: read model from config, iterate ≤ max, escalate on exhaustion
- [x] **2.2** Resume rules: read state → restate next unchecked item → never redo `[x]` items
- [x] **2.3** Verification: ask before device access; cluster bugs by root cause into one sub-feature
- [x] **2.4** Cleanup: confirm before deleting transient screenshots; rewrite image refs
- [x] **2.5** Commit: one logical commit per sub-feature; never commit without explicit permission
- [x] **2.6** Worktree guard: verify cwd matches `worktree:` in state before writing
- [x] **2.7** Spawn rules: route read-only agents in-harness, write agents per runner config
- [x] **2.8** Meta-harness detection → suggest-once behavior; never delegate on detection alone
- [x] **2.8b** Generate the runner block from the initial prompt; present for approval
- [x] **2.9** Handoff emits the spawn command for the configured runner + the canonical delegate prompt
- [x] **2.10** Handoff return path: re-verify, flip mode, cluster failures (Decision 13)
- [x] **2.11** Worktree mismatch response: STOP before any write, show both paths, ask switch-vs-update
- [x] **2.12** Device busy: never seize; offer tests-only verification and mark verify partial
- [x] **2.13** Concurrent-session guard: warn if state file changed on disk since read
- [x] **2.14** Sub-feature `cancelled` mode so a skipped sub-feature doesn't block `done/`
- [x] **2.15** PRD↔plan conflict: PRD wins; plan review checks conformance and flags drift

**Verify phase 2:**
- [x] **2.T1** Manual — Every phase in SKILL.md has matching agent instructions here
- [x] **2.T2** Manual — "Checklist wins over state file" rule is explicit
- [x] **2.T3** Manual — Bug clustering rule says "wait for full pass, group by root cause"
- [x] **2.T4** Manual — Fallback is warn-and-continue; no path hard-fails on a missing harness

---

### Phase 3 — Adapter + docs

- [x] **3.1** Add `evals/` + `CONTRIBUTING.md` skip-guard to `adapters/claude-code/install.sh:29`
- [x] **3.2** Add `sdlc:` block to `.vibekit.yaml.example`
- [x] **3.3** Add `sdlc` row to `CLAUDE.md` skills table
- [x] **3.4** Add `sdlc` row to `README.md` skills table + dir tree

**Verify phase 3:**
- [x] **3.T1** Integration — `./install.sh claude-code`; `~/.claude/skills/sdlc/SKILL.md` exists
- [x] **3.T2** Integration — Reinstall; neither `skills/sdlc/evals/` nor any `CONTRIBUTING.md` lands in `~/.claude/skills/`
- [x] **3.T3** Manual — `.vibekit.yaml.example` parses as valid YAML

---

### Phase 4 — End-to-end validation

- [ ] **4.1** `/sdlc test-feature` → creates `pending/test-feature/` + state file
- [ ] **4.2** Reviewer spawns with model from config (verify it honors an override)
- [ ] **4.6** `runner.mode: meta-harness` with no harness present → warns, continues in-harness
- [ ] **4.7** No `.vibekit.yaml`, inside a `.vibe-station/` path → ALL roles in-harness; suggestion printed once
- [ ] **4.3** Decomposition creates `NN-` sub-feature dirs with correct filenames
- [ ] **4.4** Simulated bug bundle → ONE new sub-feature with `origin: bug-bundle` + `spawned_from`
- [ ] **4.5** Feature dir moves pending → wip → done across the lifecycle

**Verify phase 4:**
- [ ] **4.T1** Integration — Filenames match `plan-<NN>-<feature>-<sub>.md` exactly
- [ ] **4.T2** Integration — No `.vibekit.yaml` present → transient screenshots, nothing committed
- [ ] **4.T3** Integration — Resume mid-sub-feature does not re-run `[x]` items
- [ ] **4.T4** Regression — `/prd` and `/planning` still work standalone without sdlc

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `skills/sdlc/SKILL.md` | 1.1-1.6 | New — orchestration + config + decomposition |
| `skills/sdlc/PHASES.md` | 2.1-2.6 | New — per-phase agent behavior |
| `adapters/claude-code/install.sh` | 3.1 | Skip `evals/` + `CONTRIBUTING.md` on copy |
| `.vibekit.yaml.example` | 3.2 | `sdlc:` block |
| `CLAUDE.md` | 3.3 | Skills table row |
| `README.md` | 3.4 | Skills table + dir tree |
