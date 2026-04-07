# Feature plan format — Agent guide

Plans live in `.feature-plans/` (`pending/`, `wip/`, `done/`). See `_plan_sample_format.md` for the template.

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

1. **Frontmatter** — Issue, Branch, Status
2. **Problem** — 1-3 bullets: what's broken / missing
3. **Concept** — High-level user-facing behavior
4. **Requirements** — Numbered table
5. **Research** — Bullet-point findings with file paths + line numbers
6. **Root Cause** — Core issue in 1-2 bullets
7. **Approach** — Architecture, Data Model, Fix bullets (`file.ext:line`)
8. **Files to Modify** — Table: `| File | Change |`
9. **Risks / Open Questions** — Table: `| # | Question | Notes |`
10. **Validation** — Unit, integration, regression bullets
11. **Implementation Phases** — Phased checkboxes: `- [ ] **N.1** Do X in \`file.ext\``
12. **Files Summary** — Table mapping file → phase → change

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
- [ ] Files summary table present
- [ ] ASCII flow used where a sequence matters
- [ ] File paths include line numbers where specific
