---
name: prd
description: Product requirements document for larger features — user-facing behavior, options, decisions, screen layouts, and open questions. Precedes the technical plan.
version: 0.1.0
triggers:
  - "write a PRD"
  - "write a product requirements doc"
  - "/prd"
globs:
  - ".feature-plans/**"
---

# PRD skill

Use this skill before writing a technical plan when a feature is large enough to warrant capturing *what* and *why* before jumping into *how*.

## When to write a PRD

- Feature spans multiple user-facing screens or changes an existing UX flow
- There are genuine options or trade-offs to document before committing to an approach
- Multiple stakeholders (or future-you) need to understand the intent months later
- The feature has non-trivial edge cases, back-navigation rules, or out-of-scope boundaries

## When NOT to write a PRD

- Pure refactors with no behavior change
- Bug fixes with a clear root cause and fix
- Small enhancements with an obvious, unambiguous implementation

## Workflow

```
PRD  →  Technical Plan  →  Implementation
```

1. Create `.feature-plans/pending/<feature>/prd-<feature>.md` (this skill) — **directory mode, primary**
   - Sub-feature PRD (only when the master PRD doesn't cover it): `<feature>/NN-<sub>/prd-<NN>-<feature>-<sub>.md`
   - **Backward compat:** `.feature-plans/pending/prd-<slug>.md` (flat file) still works for existing projects
2. Once the PRD is reviewed and decisions are settled, create `.feature-plans/pending/<feature>/plan-<feature>.md` (planning skill)
3. Link the two files via frontmatter (`prd:` and `plan:` fields)

## Format rules

Read [`FORMAT.md`](./FORMAT.md) before writing — it has the requirement-writing rules and header block.

- Requirements: **one crisp line each** — no multi-sentence descriptions
- Requirements describe user-facing behavior, not implementation steps
- No file paths, no code references
- See `_prd_sample_format.md` for the template
