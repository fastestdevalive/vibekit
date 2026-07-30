# PRD format — Agent guide

- PRDs live in `.vibekit/feature-plans/<state>/<feature>/`
- See `_prd_sample_format.md` for the template

---

## Document header block (required)

Every PRD starts with this block right after frontmatter:

```markdown
<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->
```

---

## Writing style

- PRDs are **behavioral, not prose** — same bullet/table discipline as the technical plan
- Requirements are one crisp line each, describing user-facing behavior, not implementation details

| Do | Don't |
|----|-------|
| One crisp line per requirement | Multi-sentence descriptions |
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
5. **Requirements** — numbered sections (§1, §2 …), each with a requirements table using short IDs (R1, R2 …) and one-line requirements
6. **Options considered** — table for any A/B/C decision; mark the chosen option
7. **Resolved design questions** — explicit record of decisions made and why
8. **Screen layouts** — ASCII diagrams for any new or significantly changed screens
9. **Priority & sequencing** — dependency table if the feature has sub-parts that must ship in order
10. **Open questions** — anything still unresolved; each should have an owner or proposed answer

---

## Requirements format

Use numbered sections with a table inside each:

```markdown
## 1. Feature Area Name

| ID | Requirement |
|----|-------------|
| R1 | One crisp line — observable user-facing behavior, testable. |
| R2 | Constraint or non-functional requirement. |
```

- IDs are short and section-scoped: `R1`–`Rn`, or prefixed by section letter (`S1`, `G1`) for disambiguation
- Each requirement is **one line, no more** — split into two rows if it needs a second sentence
- Do not add implementation detail to requirement rows

---

## Options format

When there are genuine design alternatives, use a table (or the two-option compact form):

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| A — name | ... | ... | ✅ chosen |
| B — name | ... | ... | ❌ deferred |

```markdown
**Option A — [Name] (chosen)** — one line. **Option B — [Name]** — one line.
**Decision:** Option A because [one-line reason].
```

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
- Add notes below the diagram for non-obvious behavior — bullets, one line each

---

## Resolved design questions

- Use this section to permanently record decisions
- Avoid reopening them in the technical plan

```markdown
## Resolved design questions

1. **Question?** — **Answer.** One-line rationale.
2. **Question?** — **Answer.** One-line rationale.
```

---

## Checklist before finalising a PRD

- [ ] Title and first line make scope clear without reading the body
- [ ] Header block present, right after frontmatter
- [ ] Non-goals are explicit
- [ ] Every requirement is one crisp, testable line — no multi-sentence rows
- [ ] All options have a recorded decision + rationale
- [ ] Every new screen has an ASCII layout
- [ ] Open questions are listed; none are buried in requirement text
- [ ] Technical plan slug is linked in frontmatter once the plan exists
