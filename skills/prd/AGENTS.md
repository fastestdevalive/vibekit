# PRD format — Agent guide

PRDs live in `.feature-plans/` (`pending/`, `wip/`, `done/`). See `_prd_sample_format.md` for the template.

---

## Writing style

PRDs are **prose-first** — opposite of the technical plan. Requirements are written as full sentences that describe user-facing behavior, not implementation details.

| Do | Don't |
|----|-------|
| Full sentences for requirements | Bullet-only fragments |
| Describe user-facing behavior | Reference file paths or code |
| State what and why | State how |
| Record options and the decision made | Leave decisions implicit |
| ASCII layouts for new screens | Wireframe links (prefer self-contained) |

---

## Sections

All PRDs follow this structure (see `_prd_sample_format.md`):

1. **Title + one-liner** — feature name and scope
2. **Frontmatter** — Status, linked technical plan slug
3. **Problem** — 1–3 bullets: what's broken or missing today
4. **Goals** — what success looks like; **Non-goals** — explicit out-of-scope
5. **Requirements** — numbered sections (§1, §2 …), each with a requirements table using short IDs (R1, R2 …) and prose descriptions
6. **Options considered** — table or short prose for any A/B/C decision; mark the chosen option
7. **Resolved design questions** — explicit record of decisions made and why
8. **Screen layouts** — ASCII diagrams for any new or significantly changed screens
9. **Priority & sequencing** — dependency table if the feature has sub-parts that must ship in order
10. **Open questions** — anything still unresolved; each should have an owner or proposed answer

---

## Requirements format

Use numbered sections with a table inside each:

```markdown
## 1. Feature Area Name

One sentence explaining what this section covers.

| ID | Requirement |
|----|-------------|
| R1 | Full sentence describing observable user-facing behavior. |
| R2 | Constraint or non-functional requirement. |
```

- IDs are short and section-scoped: `R1`–`Rn`, or prefixed by section letter (`S1`, `G1`) for disambiguation.
- Each requirement is one complete sentence — specific enough to be testable.
- Do not add implementation detail to requirement rows.

---

## Options format

When there are genuine design alternatives:

```markdown
**Option A — [Name] (chosen)**
Brief description. Pros: X. Cons: Y.

**Option B — [Name]**
Brief description. Pros: X. Cons: Y.

**Decision:** Option A because [reason].
```

Or as a table when comparing more than two:

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| A — name | ... | ... | ✅ chosen |
| B — name | ... | ... | ❌ deferred |

---

## Screen layouts

Use ASCII for new screens or significantly changed flows:

```
┌──────────────────────────────────┐
│  Screen Title                    │
│                                  │
│  [Main content area]             │
│                                  │
│  ┌──────────────────────────┐   │
│  │  Primary CTA             │   │
│  └──────────────────────────┘   │
└──────────────────────────────────┘
```

- One diagram per distinct screen or state
- Label each zone clearly
- Add notes below the diagram for non-obvious behavior

---

## Resolved design questions

Use this section to permanently record decisions. Avoid reopening them in the technical plan.

```markdown
## Resolved design questions

1. **Question?** — **Answer.** Brief rationale.
2. **Question?** — **Answer.** Brief rationale.
```

---

## Checklist before finalising a PRD

- [ ] Title and first line make scope clear without reading the body
- [ ] Non-goals are explicit
- [ ] Every requirement is a complete, testable sentence
- [ ] All options have a recorded decision + rationale
- [ ] Every new screen has an ASCII layout
- [ ] Open questions are listed; none are buried in requirement prose
- [ ] Technical plan slug is linked in frontmatter once the plan exists
