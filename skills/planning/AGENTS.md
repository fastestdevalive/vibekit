# Feature plan format — Agent guide

Plans live in `.feature-plans/` (`pending/`, `wip/`, `done/`). See `_plan_sample_format.md` for the template.
For larger features, a PRD should exist before this plan — link it in the `PRD:` frontmatter field.

---

## Writing style

- **Bullet points only** — no full sentences or prose paragraphs
- Include file paths + line numbers for every code reference
- Keep research findings to: file, trigger, risk level, and why
- Approach sections: what changes, where, key behavioral difference
- No code blocks unless showing a specific API contract or critical snippet

---

## Format rules

| Element | Use for |
|--------|--------|
| **Bullet lists** | Causes, fixes, steps, options |
| **Tables** | Before/after, file\|change, risk matrix, status |
| **ASCII flow** | Sequences: `A → B → C` or `Step 1 → Step 2` |
| **Short headers** | `### 1.1 — ComponentName: One-line issue` |
| **Numbered lists** | Implementation order, ordered steps |

### Avoid

- Long sentences and multi-sentence paragraphs
- Prose explanations — use bullets or a table instead
- Buried actions inside paragraphs — extract as **Fix:** bullets or table
- Code blocks beyond short API contracts or critical snippets

---

## Plan structure

All plans follow this structure (see `_plan_sample_format.md`):

1. **Frontmatter** — Issue, Branch, Status, PRD link
2. **Problem** — 1-3 bullets: what's broken / missing
3. **Concept** — High-level user-facing behavior
4. **Requirements** — Numbered table
5. **Research** — Bullet-point findings with file paths + line numbers
6. **Root Cause** — Core issue in 1-2 bullets
7. **Approach** — Architecture, Data Model, Fix bullets (`file.ext:line`)
8. **Files to Modify** — Table: `| File | Change |`
9. **Risks / Open Questions** — Table: `| # | Question | Notes |`
10. **Implementation Phases** — Phased checklist with test verification blocks
11. **Files Summary** — Table mapping file → phase → change

---

## Implementation phases and test verification

Every phase ends with a **"Verify phase N"** block. The phase is not done until those tests pass.

### Numbering

- Implementation items: `N.1`, `N.2`, `N.3` …
- Test items: `N.T1`, `N.T2` … (T prefix distinguishes them from implementation steps)

### Test item format

```markdown
- [ ] **1.T1** Unit — `ClassName`: [specific assertion in plain language]
- [ ] **1.T2** Integration — `[flow name]`: [trigger → expected outcome]
- [ ] **1.T3** Regression — `[existing flow]`: [behavior that must still pass]
```

Each test item must specify:
1. **Type** — Unit / Integration / Regression
2. **Class or flow** — the test file/class name, or the flow being verified end-to-end
3. **What it verifies** — one plain-language assertion (not "test it works")

### Unit vs integration

| Type | Scope | When to use |
|------|-------|-------------|
| **Unit** | Single class / function in isolation | Pure logic, data transformations, state machines |
| **Integration** | Multiple components or system boundary | Persistence, navigation, real repositories, UI + state |
| **Regression** | Previously passing flow | Any time an existing behavior could be affected by the phase |

### Rules

- Every phase must have at least one test item (unit or integration)
- Test items live at the end of the phase, in a `**Verify phase N:**` block — not scattered between implementation items
- Test files belong in the Files Summary table alongside source files
- "Write tests" without a class name or assertion is not a valid test item — be specific

---

## Tables

Use tables for structured data:

- **File changes:** `| File | Change |`
- **Risk matrix:** `| # | Question | Notes |`
- **Config / state:** `| Variant | Current | Target |`
- **Options:** `| Option | Pros | Cons |`

Keep cell content short; use bullets inside cells only if needed.

---

## ASCII flows

Use for sequences and data/UI flow:

```
User action → Controller → Service → Store commit
                ↓
           UI state → Render
```

- One line per step or level
- Indent for nested steps
- Arrow `→` for "then" or "leads to"

---

## Checklist before committing a plan

- [ ] Title and first line make scope clear
- [ ] No long paragraphs — bullets and tables only
- [ ] Each issue has Problem + Fix + File(s)
- [ ] Files summary table present (includes test files)
- [ ] ASCII flow used where a sequence matters
- [ ] File paths include line numbers where specific
- [ ] Every phase has a `**Verify phase N:**` block with named, specific test items
- [ ] Test items distinguish unit from integration/regression
