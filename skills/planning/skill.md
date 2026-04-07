---
name: planning
description: Structured feature planning with strict bullet-point format, file/line references, and phased implementation checklists
version: 0.1.0
triggers:
  - "plan a feature"
  - "write a feature plan"
  - "/plan"
globs:
  - ".feature-plans/**"
---

# Planning skill

Use this skill whenever you are about to start non-trivial implementation work and want to align on the approach before writing code.

## When to use

- Multi-file changes with non-obvious sequencing
- Features that touch data model + UI + persistence
- Bug fixes where root cause is unclear and you need a research phase
- Refactors spanning multiple modules

## When NOT to use

- One-line fixes
- Pure docs / comment changes
- Exploratory throwaway scripts

## How to use

1. Create a new plan file under `.feature-plans/pending/<slug>.md`
2. Copy the structure from [`_plan_sample_format.md`](./_plan_sample_format.md)
3. Follow the writing rules in [`AGENTS.md`](./AGENTS.md):
   - **Bullet points only** — no prose paragraphs
   - File paths + line numbers for every code reference
   - Tables for files-to-modify and risks
   - Phased checklist for implementation
4. Move the file to `wip/` when work begins, `done/` when complete

## Scaffolding a new project

```bash
./scaffold.sh /path/to/project
```

This creates `.feature-plans/{pending,wip,done}/` and copies the template + agent guide into the target project.
