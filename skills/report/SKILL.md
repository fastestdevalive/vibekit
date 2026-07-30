---
name: report
description: One-shot investigation → findings document. No state, no checklist, no phases — investigate, write the answer, stop.
version: 0.1.0
triggers:
  - "/report"
  - "write a report"
  - "investigate and report"
globs:
  - ".reports/**"
---

# Report skill

Use this skill for one-shot, local-evidence investigation that ends in a findings document — not an implementation.

- **One-shot** — investigate, write findings, stop. No state file, no checklist, no phases, no resume
- Read the `planning` skill's `FORMAT.md` for the header block and the allowed/banned elements table
  - This skill's location and screenshot rules **override** `FORMAT.md`'s plan-specific sections — its checklist rules, `.feature-plans` screenshot paths, and self-containment bar do NOT apply here

## When to use

| Situation | Skill |
|-----------|-------|
| Pure question-answering, nothing will change as a result | `report` (this skill) |
| Investigation feeding an intended change | `planning` — put it in the plan's `Research` section |

- A report may later be pasted into a plan's Research section — the report itself is not the plan
- Out of scope: web research — local evidence only, no skill routing for it

## Report kinds

| Kind | Typical trigger | Evidence is |
|------|-----------------|-------------|
| Codebase map | "how does X work" | `file:line` refs, module diagram |
| Behavior audit | "does X actually do Y" | commands + real output |
| Device/UI check | "how does this screen look" | screenshots + layout notes |
| Comparison | "X vs Y in this repo" | side-by-side table |
| Health check | "what's broken here" | failing command output |

- One skill, not five — the template below holds for all of them; only the Evidence column changes

## Output location + naming

```
.reports/
  2026-07-29-auth-flow-codebase-map.md
  2026-07-29-settings-screen-device-audit/
    report.md
    screenshots/           ← gitignored unless the project opts into permanent
```

- **Not** under `.feature-plans/` — a report is not a plan; no `pending → wip → done` lifecycle
- Flat `.md` file by default; a directory only when the report has screenshots
- Filename: `YYYY-MM-DD-<slug>.md` — date-prefixed because a report is a snapshot of a moment
- **Never edit a report in place** — superseding it means writing a new dated report

## Template

Use [`_template_report.md`](./_template_report.md) — Answer → Evidence → Detail → Not checked → Follow-ups.

## Device protocol

- Ask before device access — devices are shared across sessions (never seize)

## Screenshots

- Path: `.reports/<YYYY-MM-DD-slug>/screenshots/<descriptive-name>.png`
- Embed with `![alt](./screenshots/name.png)`
- **Bootstrap:** on the first report in this project that contains a screenshot, if `.reports/.gitignore` does not exist, create it with:
  ```
  **/screenshots/
  ```
- A project opting into permanent screenshots (keeping them committed) must NOT create that gitignore rule — and must remove it if already present

## Writing rules

- Bullets, tables, code blocks, diagrams only — no prose paragraphs (see `FORMAT.md`)
- **Answer first** — the reader should not have to reach the bottom for the conclusion
- Every claim cites `file:line`, a command + its real output, or a screenshot
- `## Not checked` is mandatory — name at least one concrete unexamined area, or state why coverage is total; `- Nothing` is not acceptable
- **Commit SHA is mandatory** — a point-in-time snapshot of a codebase is meaningless without the commit examined
