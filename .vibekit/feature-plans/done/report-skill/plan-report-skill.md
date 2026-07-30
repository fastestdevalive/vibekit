<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# Plan: `report` skill — one-shot investigation → findings doc

**Issue:** report-skill
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26`
**Status:** Done — closed 2026-07-30

---

## Problem

- One-shot work (explore a codebase, screenshot a device, check a behavior) has no skill
- `sdlc` is far too heavy — state file, sub-features, checklists, review loop
- `planning` produces something to **execute**; a report is something to **read**
- Output format is re-explained every time; findings drift into prose paragraphs
- Findings live only in chat → lost at compaction, re-derived next session

## Out of scope

- Anything with an implementation checklist → that's `plan`
- Multi-session work with resumable state → that's `sdlc`
- Web research — out of scope; no skill routing, this is local-evidence only

---

## Concept

- New `report` skill: **investigate → write findings → stop.** No state, no checklist, no phases
- Reuses existing machinery rather than restating it:
  - Format rules → `planning` skill's `FORMAT.md`, **scoped**: header block + allowed/banned elements only
    - Its checklist, `.feature-plans` screenshot paths, and self-containment sections are plan-specific and do NOT apply
  - Device protocol → **restated verbatim** in this skill; no `sdlc` file or `sdlc.*` config key is cited
  - Screenshots → hardcoded `.reports/<YYYY-MM-DD-slug>/screenshots/`; no config key in V1
- Trigger: `/report <what to find out>`

**Routing vs `planning`** — `planning/SKILL.md:32` also claims investigation ("bug fixes where root cause is unclear"):

- **Will anything change as a result?** → the investigation belongs in a plan's `Research` section
- **Pure question-answering, no intended change?** → `report`
- A report may later be pasted into a plan's Research section — the report is not the plan

## Requirements

| # | Requirement |
|---|-------------|
| 1 | One-shot — runs to a finished document, no resumable state |
| 2 | Output is bullets/tables/code/diagrams — **no prose paragraphs** |
| 3 | Reuses `FORMAT.md` rules by reference; does not restate them |
| 4 | Reports are **point-in-time snapshots** — dated, never edited in place |
| 5 | Every claim cites `file:line`, a command + its output, or a screenshot |
| 6 | Screenshots live in `.reports/<report-dir>/screenshots/` and are gitignored by default |
| 7 | Ask before touching a shared device |
| 8 | States explicitly what was NOT checked |

---

## Where reports live

```
.reports/
  2026-07-29-auth-flow-codebase-map.md
  2026-07-29-settings-screen-device-audit/
    report.md
    screenshots/           ← gitignored unless policy: permanent
```

- **Not** under `.feature-plans/` — reports are not plans; the `pending → wip → done` lifecycle does not apply
- Flat file by default; a directory only when screenshots exist
- **Date-prefixed** because a report is a snapshot of a moment, unlike a plan which is a living doc
- Filename: `YYYY-MM-DD-<slug>.md`
- Superseding a report = write a new dated one; never edit the old one

---

## Report template

```markdown
# Report: <question being answered>

**Date:** YYYY-MM-DD · **Commit:** <sha> · **Scope:** <what was examined> · **Method:** <how>

## Answer
- The finding, in 1-3 bullets, first — before any evidence

## Evidence
| Claim | Source |
|-------|--------|
| … | `path/to/file.ext:123` |
| … | `$ cmd` → output |
| … | `![login state](./screenshots/login.png)` |

## Detail
- Per-area findings, bullets only
- Diagrams where >3 relationships are involved

## Not checked
- Explicit list of what this report does NOT cover
- Must name at least one concrete unexamined area, or state why coverage is total
- `- Nothing` / empty is not acceptable

## Follow-ups
| # | Question | Why it matters |
```

- **Answer first** — the reader should not have to reach the bottom for the conclusion
- `Not checked` is mandatory — an unbounded report reads as exhaustive when it isn't
- **Commit SHA** is mandatory — a point-in-time snapshot of a codebase is meaningless without the commit examined
- Enforcement note: reports live in target projects, outside `lint.sh` reach — the template bans the empty cop-out, but this is a convention, not a machine check

---

## Report kinds

| Kind | Typical trigger | Evidence is |
|------|----------------|-------------|
| Codebase map | "how does X work" | `file:line` refs, module diagram |
| Behavior audit | "does X actually do Y" | commands + real output |
| Device/UI check | "how does this screen look" | screenshots + layout notes |
| Comparison | "X vs Y in this repo" | side-by-side table |
| Health check | "what's broken here" | failing command output |

- One skill, not five — the template holds; only the Evidence column changes

---

## Alternatives considered

| Option | Verdict |
|--------|---------|
| **A — new `report` skill** | ✅ Proposed — small, no state, reuses existing rules |
| B — a `/sdlc report` subcommand | ❌ Drags in state file, sub-features, gate — none apply to a one-shot |
| C — extend `planning` | ❌ A plan is executable; a report is not. Mixing them muddies the selector we just fixed |
| D — no skill, just ask each time | ❌ The status quo; format drifts and findings are lost at compaction |

---

## Open questions

| # | Question | **Decided** |
|---|----------|-------------|
| 1 | `.reports/` gitignored or committed? | **Committed** — findings are the value; markdown is cheap. Screenshots stay gitignored |
| 2 | Should `/sdlc` emit reports? | **NO — decided by the user.** `sdlc` and `report` stay fully independent; no cross-reference in either direction |
| 3 | Own `FORMAT.md`? | **No** — read `planning`'s; a second copy would drift |
| 4 | Auto-delete stale reports? | **No** — dated records; pruning is the user's call |

---

## Files to Modify

| File | Change |
|------|--------|
| `skills/report/SKILL.md` | New — when to use, report kinds, output location, imperative read of `planning` |
| `skills/report/_template_report.md` | New — the template above |
| `CLAUDE.md`, `README.md`, root `AGENTS.md` | Skills tables + repo layout |
| `skills/sdlc/evals/lint.sh` | Add `report:planning` edge; add report files to the line-cap loop |
| `.gitignore` or `.reports/.gitignore` | `**/screenshots/` — reports committed, screenshots not |

- **No change to `sdlc`, `planning`, or `prd`** — independence is a decided constraint, not an accident
- **Cursor/Gemini ship `SKILL.md` only** — the `_template_report.md` link is dead there, the same accepted degradation as `planning`'s `FORMAT.md`

---

## Implementation Phases

### Phase 1 — Create the skill

- [x] **1.1** Create `skills/report/SKILL.md` with frontmatter (`name`, `description`, `version`, `triggers: /report`, `globs: .reports/**`)
- [x] **1.2** Add "when to use / when NOT to use" with the routing rule: *will anything change as a
      result?* → plan's Research section; *pure question-answering* → `report`
- [x] **1.3** Add the imperative format edge, scoped: "**Read the `planning` skill's `FORMAT.md`** for the
      header block and allowed/banned elements. This skill's location and screenshot rules override
      FORMAT.md's plan-specific sections (checklist, `.feature-plans` paths, self-containment)"
- [x] **1.4** Add the report-kinds table (codebase map, behavior audit, device check, comparison, health check)
- [x] **1.5** Add output location + `YYYY-MM-DD-<slug>.md` naming + never-edit-in-place rule
- [x] **1.6** Restate the device rule **verbatim** in `skills/report/SKILL.md`: ask before access, never seize a shared device. Cite no `sdlc` file and no `sdlc.*` config key
- [x] **1.7** Add screenshot handling: hardcoded `.reports/<YYYY-MM-DD-slug>/screenshots/`
- [x] **1.7b** **Bootstrap instruction** — SKILL.md tells the agent: on the first report containing
      screenshots, create `.reports/.gitignore` with `**/screenshots/` if absent
      (mirrors the `.feature-plans/.gitignore` precedent at `scaffold.sh:31`)
- [x] **1.7c** State that under a project opting into permanent screenshots, the agent must not
      create — or must remove — that ignore rule
- [x] **1.8** Link `_template_report.md` from SKILL.md (unlinked = never loaded)

**Verify phase 1:**
- [x] **1.T1** Integration — SKILL.md contains the `.reports/.gitignore` bootstrap instruction (the delivery mechanism, not just the dogfood file)
- [x] **1.T2** Integration — `wc -l skills/report/SKILL.md` < 200
- [x] **1.T3** Manual — SKILL.md states no state file, no checklist, one-shot

---

### Phase 2 — Template + config

- [x] **2.1** Create `skills/report/_template_report.md` — Answer → Evidence → Detail → Not checked → Follow-ups
- [x] **2.2** Add the doc header block (same 4 rules as plans)
- [x] **2.3** Mark `## Not checked` as mandatory in the template
- [x] **2.5** Add `.reports/.gitignore` with `**/screenshots/`

**Verify phase 2:**
- [x] **2.T1** Manual — template leads with Answer, not Evidence
- [x] **2.T2** Integration — a `.png` under `.reports/x/screenshots/` is matched by `git check-ignore`
- [x] **2.T3** Integration — a `.md` under `.reports/` is NOT ignored

---

### Phase 3 — Wire into repo docs + lint

- [x] **3.1** Add `report` to `CLAUDE.md` + `README.md` + root `AGENTS.md` skills tables
- [x] **3.2** Add `.reports/` to the repo-layout blocks
- [x] **3.3** Add `report:planning` to the `EDGES` list in `lint.sh`
- [x] **3.3b** Add `skills/report/SKILL.md` + `_template_report.md` to the lint line-cap loop (`lint.sh:31-38`) so the cap can't regress silently
- [x] **3.4** Run `./install.sh claude-code` and confirm `report` installs

**Verify phase 3:**
- [x] **3.T1** Integration — `bash skills/sdlc/evals/lint.sh` exits 0 with the new edge present
- [x] **3.T2** Integration — lint FAILS when the imperative read line is removed from `report/SKILL.md`
- [x] **3.T3** Integration — `~/.claude/skills/report/` contains SKILL.md + template
- [x] **3.T4** Integration — ``grep -rnE '`report`|skills/report|/report\b' skills/sdlc/`` returns EMPTY
      (plain `grep -rn "report"` matches 13 lines of ordinary English today — it would fail a correct build)
- [x] **3.T5** Integration — `grep -rniE 'sdlc' skills/report/` returns EMPTY (reverse direction)

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `skills/report/SKILL.md` | 1.1-1.8 | New skill |
| `skills/report/_template_report.md` | 2.1-2.3 | New template |
| `.reports/.gitignore` | 2.5 | screenshots only |
| `CLAUDE.md`, `README.md`, `AGENTS.md` | 3.1-3.2 | Skills tables + layout |
| `skills/sdlc/evals/lint.sh` | 3.3 | `report:planning` edge |
