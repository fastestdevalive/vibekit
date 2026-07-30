---
name: coding-agent-guardrails
description: Universal code quality guardrails — file size limits, code structure, VCS discipline, and build behavior for any project
version: 0.2.0
triggers:
  - "set up guardrails"
  - "add guardrails"
  - "/coding-agent-guardrails"
  - "/guardrails"        # legacy alias — keep
globs:
  - "AGENTS.md"
  - "CLAUDE.md"
  - "GEMINI.md"
  - "agents/**"
---

# Coding-agent guardrails

Universal rules for any codebase — apply these on every file you touch.

## File size limits

- **Source files: hard ceiling at 1,500 lines.** If a file you are editing approaches or exceeds this limit, split it before or as part of your change. Never leave a file over 1,500 lines in a merged state.
- **Doc files: cap by when the file loads, not what it is** — the constraint tracks context cost, not raw size:

| Class | Files | Cap | Why |
|-------|-------|----:|-----|
| Always-loaded | `SKILL.md` (every skill), root `CLAUDE.md`, root `AGENTS.md`, `GEMINI.md` | **400** | Costs context on every invocation |
| On-demand companions | `FORMAT.md`, `SECTIONS.md`, `PHASES.md`, `GRAMMAR.md`, `EXAMPLES.md` | **600** | Loaded only when the phase needs it |
| Templates | `_template_*.md`, `_*_sample_*.md` | **none** | Copied, never loaded as context |

- Split into focused sub-guides when a file approaches its class cap

## Code organization

- Organize by **feature**, not by layer — avoid top-level `controllers/`, `models/`, `views/` mega-directories.
- A feature's entry point, screen/view, and view-model/controller live **co-located** in the feature directory.
- **Sub-components** of a screen belong in a `components/` subdirectory relative to that screen (e.g. `feature/settings/components/` next to `SettingsScreen`).
- **Cross-feature reusables** belong in `common/` (or `shared/`).
- When a class would exceed the line limit, extract pure logic into a companion `<Name>Logic` or extension file in the same package — do not inflate the original.
- Keep directory trees **shallow and semantically grouped** — 2–3 levels of nesting is the norm; avoid both flat mega-directories and over-nested hierarchies.

## VCS discipline

- **Never run `git commit` or `git add` without explicit user permission.** Always ask before staging or committing.
- When asked to commit, stage only files relevant to the task — not everything in the working tree.

## Build behavior

- **Ignore build warnings.** Only errors need to be fixed.
- Do not change working code just to silence a warning unless the user explicitly asks.
