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
  - ".vibekit/feature-plans/**"
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

1. Create the feature directory: `.vibekit/feature-plans/pending/<feature>/` (**primary** — directory mode)
   - Simple features skip sub-feature dirs — just `.vibekit/feature-plans/pending/<feature>/plan-<feature>.md`
   - Sub-features nest: `.vibekit/feature-plans/pending/<feature>/NN-<sub>/plan-<NN>-<feature>-<sub>.md`
   - **Backward compat (secondary):** a flat `.vibekit/feature-plans/pending/<slug>.md` file still works — see Detection rule below
2. Pick the right template — see [Which template?](#which-template)
3. Follow the writing rules in [`FORMAT.md`](./FORMAT.md) — read this before writing or implementing:
   - **Bullet points only** — no prose paragraphs
   - File paths + line numbers for every code reference
   - Files & Phase Impact table for files/phases/contracts, and a table for risks
   - Phased checklist with **per-phase test verification** (`N.T1`, `N.T2` …)
   - Header block, checklist rules, system boundaries, self-containment bar
   - Enforce single-sentence constraint during plan review phase
4. Follow the per-section templates in [`SECTIONS.md`](./SECTIONS.md) — what each section of the plan contains, diagram-type table
5. Move the whole feature directory to `wip/` when work begins, `done/` when complete

## Which template?

- **[`_template_plan.md`](./_template_plan.md)** — the default. Carries the implementation checklist.
  Use it for any work you will actually execute, however large.
  It may spawn sub-plans (bug bundles, follow-ups) and still keeps its own checklist.

- **[`_template_arch.md`](./_template_arch.md)** — only when a feature needs system-level decomposition
  before anything is executable. No implementation phases; its output is parts,
  each of which is a plan.

- If unsure: use `plan`
- Most features never need an arch

### File naming convention

| Doc | Pattern | Example |
|-----|---------|---------|
| Master PRD | `prd-<feature>.md` | `prd-auth-flow.md` |
| Master plan | `plan-<feature>.md` | `plan-auth-flow.md` |
| Master arch _(rare)_ | `arch-<feature>.md` | `arch-auth-flow.md` |
| Sub-feature PRD | `prd-<NN>-<feature>-<subfeature>.md` | `prd-02-auth-flow-api.md` |
| Sub-feature plan | `plan-<NN>-<feature>-<subfeature>.md` | `plan-02-auth-flow-api.md` |

- **Feature name in every filename** — fuzzy-find by feature name surfaces every related doc regardless of directory
- **`NN` in every sub-feature filename** — execution order is visible in flat search results and editor tabs, where the parent directory isn't shown
- `NN` is assigned once and **never renumbered** — new sub-features always append; a bug bundle found after `03` becomes `04`, never `02.5`

### Detection rule (flat vs directory mode, used on resume)

```
given <name> under pending|wip|done:
  <name>/ is a directory  → directory mode; read <name>/.sdlc-state.yaml if present
  <name>.md is a file     → flat mode; no state file, no sub-features
  both exist               → prefer directory; warn about the stray flat file
```

- New features always use directory mode; flat mode is read-only compatibility for existing projects

## Scaffolding a new project

```bash
./scaffold.sh /path/to/project
```

This creates `.vibekit/feature-plans/{pending,wip,done}/` and copies the template + agent guide into the target project.
