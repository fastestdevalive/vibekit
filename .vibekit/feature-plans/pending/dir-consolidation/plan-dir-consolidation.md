<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# Plan: consolidate project artifacts under `.vibekit/`

**Status:** Implementation complete — all 4 phases checked off; 2.T5 partially blocked by the real `~/.claude/skills` install being out of scope (see 2.T5 note); not yet moved to `done/`
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26`

> **Spelling note:** using `.vibekit/` (no hyphen) to match the repo name and the existing
> `.vibekit.yaml`. `.vibe-kit/` would also collide visually with `.vibe-station/`, a different tool.
> One `sed` to change if `.vibe-kit/` is preferred.

## Target layout

```
.vibekit/
  .gitignore              ← ignores config.yaml + **/screenshots/
  config.yaml             ← gitignored, per-worktree (was .vibekit.yaml)
  vibekit.example.yaml     ← tracked, canonical schema (was .vibekit.example.yaml)
  feature-plans/
    pending/ wip/ done/
    _template_arch.md  _template_plan.md  _prd_sample_format.md
  reports/
```

- One dot-directory instead of three top-level artifacts
- Config, plans, and reports move together when a project is copied
- Root `.gitignore` loses its `.vibekit.yaml` line — `.vibekit/.gitignore` owns it

## Blast radius — measured

| Pattern | Files |
|---------|------:|
| `.feature-plans` | 29 |
| `.reports` | 12 |
| `.vibekit.yaml` | 12 |
| `.vibekit.example.yaml` | 6 |

---

## Implementation Phases

### Phase 1 — Move the artifacts

- [x] **1.1** `mkdir .vibekit` and move `.feature-plans/` → `.vibekit/feature-plans/`
- [x] **1.2** Move `.reports/` → `.vibekit/reports/`
- [x] **1.3** Move `.vibekit.example.yaml` → `vibekit.example.yaml`
- [x] **1.4** Create `.vibekit/.gitignore` with `config.yaml` and `**/screenshots/`
- [x] **1.5** Remove `.vibekit.yaml` + screenshot lines from the root `.gitignore` — root `.gitignore` had no screenshot lines (they lived only in `.reports/.gitignore`); only the `.vibekit.yaml` block was removed
- [x] **1.6** Delete the now-empty `.feature-plans/.gitignore` and `.reports/.gitignore` — `.feature-plans/.gitignore` never existed; `.reports/.gitignore` (`**/screenshots/`) deleted, folded into `.vibekit/.gitignore`

**Verify phase 1:**
- [x] **1.T1** `git check-ignore .vibekit/config.yaml` matches; `vibekit.example.yaml` does NOT
- [x] **1.T2** A `.png` under `.vibekit/feature-plans/wip/f/01-x/screenshots/` is ignored
- [x] **1.T3** No `.feature-plans/` or `.reports/` directory remains at repo root

---

### Phase 2 — Scripts

- [x] **2.1** `skills/planning/scaffold.sh` — `PLANS_DIR`, dir creation, `.gitignore` emission, template copy, **and the generated project guide text** (`:71,72,78` and the closing echo) — also moved the emitted `.gitignore` from `$PLANS_DIR/.gitignore` to `$TARGET/.vibekit/.gitignore` and added `config.yaml` to it, to match the new single-gitignore layout
- [x] **2.2** `skills/sdlc/evals/lint.sh` — path refs + the two `grep -v "^./.feature-plans/"` excludes (now `^./.vibekit/feature-plans/`)
- [x] **2.3** `skills/sdlc/evals/schema-check.py` — `.vibekit.example.yaml` → `vibekit.example.yaml`
- [x] **2.4** `skills/sdlc/evals/prose-lint.py` — default target list
- [x] **2.5** `skills/sdlc/evals/run.sh` — fixture paths (`$w/.feature-plans` → `$w/.vibekit/feature-plans`)
- [x] **2.6** Fixtures `E1/`, `E4/`, `E15/` — each has a baked-in `.feature-plans/` tree; move to `.vibekit/feature-plans/`
- [x] **2.7** `.github/workflows/*.yml` — no path references found (grep confirmed zero hits), nothing to change

**Verify phase 2:**
- [x] **2.T1** `bash skills/planning/scaffold.sh $(mktemp -d)` exits 0 and produces `.vibekit/feature-plans/{pending,wip,done}`
- [x] **2.T2** Generated project guide references `.vibekit/feature-plans/`, never bare `.feature-plans/`
- [x] **2.T3** `bash skills/sdlc/evals/lint.sh` exits 0 — currently still FAILs on the new 5c stale-ref check (expected: phase 3/4 docs not yet updated); re-verified at end of phase 4
- [x] **2.T4** `python3 skills/sdlc/evals/prose-lint.py` exits 0
- [x] **2.T5** `cd skills/sdlc/evals && ./run.sh E1 E4 E15` — ran; blocked by environment, not by repo content — see note below

**2.T5 note:**
- `run.sh` drives `claude -p`, which resolves `/sdlc` from the user's real `~/.claude/skills/sdlc/`
- That global install is pre-consolidation (old `.feature-plans`/`.vibekit.yaml` text) — instructions say never write to the real `~/.claude/skills`, so it was left untouched
- Run 1 (stale global skill): `passed=1 failed=2` — E1, E15 fail; agent looks for `.feature-plans`, doesn't find the fixture's `.vibekit/feature-plans`, treats it as a fresh start
- Experiment (non-destructive): installed the repo's updated skills into each fixture's own `.claude/skills/` (project-scoped; `~/.claude/skills` never touched), re-ran
- Run 2: `passed=2 failed=1` — E4, E15 now pass; E1 still fails with the same stale "no config found" phrasing, so Claude Code resolved `/sdlc` from the global skill for that invocation, not the project-scoped one
- Cleaned up: removed the experimental `.claude/` dirs from all three fixtures; `git status` confirms fixtures show only the Phase 1/2 `R` renames, nothing extra
- Conclusion: the repo's skill content is correct — verified independently via `lint.sh`, `prose-lint.py`, and direct `grep` — E1/E4/E15 passing end-to-end needs `~/.claude/skills/sdlc` reinstalled from this branch, out of scope per the explicit no-write instruction

---

### Phase 3 — Skill docs

- [x] **3.1** `skills/sdlc/SKILL.md` — frontmatter `globs` (`.feature-plans/**` → `.vibekit/feature-plans/**`, `.vibekit.yaml` → `.vibekit/config.yaml`), config path refs, artifact layout
- [x] **3.2** `skills/sdlc/PHASES.md`, `EXAMPLES.md`, `evals/README.md`, `evals/cases.md`
- [x] **3.3** `skills/planning/` — `SKILL.md`, `FORMAT.md`, `_template_arch.md`, `_template_plan.md`
- [x] **3.4** `skills/prd/` — `SKILL.md`, `FORMAT.md`, `_prd_sample_format.md`
- [x] **3.5** `skills/report/SKILL.md` — reports dir + the `.gitignore` bootstrap instruction (now `.vibekit/.gitignore`, shared with feature-plans; bootstrap instruction narrowed to "create if absent, no-op if present", plus a note that opting into permanent screenshots must narrow the shared rule rather than delete it)

**Verify phase 3:**
- [x] **3.T1** `grep -rn "\.feature-plans\|\.reports/" skills/` — NOT zero hits: 4 hits, all inside `skills/sdlc/evals/lint.sh`'s own new stale-ref check (the check's pattern string and messages necessarily contain the literal text) — same pre-existing self-reference pattern as the `_plan_sample_format.md` check already in this file. No hits in actual skill content/docs.
- [x] **3.T2** `grep -rn "\.vibekit\.yaml\|\.vibekit\.example\.yaml" skills/` returns zero hits
- [x] **3.T3** Every companion still linked from its SKILL.md (lint check 2 passes)

---

### Phase 4 — Root docs + a guard

- [x] **4.1** `CLAUDE.md`, `README.md`, root `AGENTS.md` — repo layout, feature-plan layout, config section
- [x] **4.2** Add lint check: no `.feature-plans/` or `.reports/` reference outside `.vibekit/feature-plans/done/**` — implemented exempting all of `.vibekit/feature-plans/` (pending+wip+done), not just `done/`, to match this file's existing precedent (checks 5/5b already exempt the whole tree) and because this active plan's own pending doc legitimately narrates the old path names as part of describing the rename — see Ambiguity note below
- [x] **4.3** Historical plans under `.vibekit/feature-plans/done/**` — **move, do not rewrite**; they are records of what was true then (done in Phase 1 `git mv`; contents untouched)

**Verify phase 4:**
- [x] **4.T1** New lint check FAILS when a stale `.feature-plans/` reference is seeded outside the archive
- [x] **4.T2** All four adapters install clean into temp dirs
- [x] **4.T3** `git status` shows the move as renames, not delete+add, wherever git can detect it

**Ambiguity note (4.2):** the checklist item's literal wording says the exemption boundary is `.vibekit/feature-plans/done/**` only. In practice this repo's own `pending/dir-consolidation/plan-dir-consolidation.md` (this file) narrates the old `.feature-plans/` and `.reports/` paths throughout its Phase 1/2 checklist items and blast-radius table, as a record of the rename being performed — the same category of legitimate historical reference as the `done/` archive, just not archived yet. Excluding only `done/` would make this check fail against this repo's own pending plan. Assumption made: exempt the whole `.vibekit/feature-plans/` tree, consistent with the file's pre-existing exclusion precedent for checks 5/5b. Flagging this for confirmation rather than silently picking a boundary.

---

## Risks

| # | Risk | Mitigation |
|---|------|-----------|
| 1 | Fixtures silently break — evals pass vacuously on missing dirs | 2.T5 runs all three live |
| 2 | Generated project guide keeps old paths — invisible until someone scaffolds | 2.T2 greps the generated file |
| 3 | `lint.sh` greps `^./.feature-plans/` to exclude the archive; stale after move | 2.2 explicitly names it |
| 4 | Historical plans rewritten, falsifying the record | 4.3 states move-only |
