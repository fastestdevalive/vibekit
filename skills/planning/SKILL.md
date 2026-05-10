---
name: planning
description: Structured technical feature plan with bullet-point format, file/line references, phased implementation checklists, and per-phase test verification
version: 0.2.0
triggers:
  - "plan a feature"
  - "write a feature plan"
  - "write a technical plan"
  - "/plan"
globs:
  - ".feature-plans/**"
---

# Planning skill

Use this skill whenever you are about to start non-trivial implementation work and want to align on the approach before writing code.

## Workflow: PRD → Technical Plan → Implementation

For larger features (new user-facing flows, multi-screen changes, data model changes):

1. **Write a PRD first** (`/prd`) — captures *what* and *why*, options, decisions, screen layouts
2. **Then write this technical plan** — captures *how*, file-by-file, phase-by-phase
3. Link the PRD in the plan's `PRD:` frontmatter field

For smaller work (bug fixes, refactors, single-screen changes), skip the PRD and start here.

## When to write a technical plan

- Multi-file changes with non-obvious sequencing
- Features that touch data model + UI + persistence
- Bug fixes where root cause is unclear and you need a research phase
- Refactors spanning multiple modules

## When NOT to write a technical plan

- One-line fixes
- Pure docs / comment changes
- Exploratory throwaway scripts

## How to use

1. Create a new plan file under `.feature-plans/pending/<slug>.md`
2. Pick the right template:
   - **Big feature / system design** → [`_plan_sample_big_feature_design.md`](./_plan_sample_big_feature_design.md) — alternatives, system context, entities, CUJs, API contract, rollout; spawns sub-plans
   - **Small feature / bug fix / mini-design** → [`_plan_sample_small_feature_bugfix.md`](./_plan_sample_small_feature_bugfix.md) — scoped phases + test verification; may reference a parent big-feature design
3. Follow the writing rules in [`AGENTS.md`](./AGENTS.md):
   - **Bullet points only** — no prose paragraphs
   - File paths + line numbers for every code reference
   - Tables for files-to-modify and risks
   - Phased checklist with **per-phase test verification** (`N.T1`, `N.T2` …)
4. Move the file to `wip/` when work begins, `done/` when complete

## Scaffolding a new project

```bash
./scaffold.sh /path/to/project
```

This creates `.feature-plans/{pending,wip,done}/` and copies the template + agent guide into the target project.
