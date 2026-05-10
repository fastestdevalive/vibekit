# Feature plan format — Agent guide

Plans live in `.feature-plans/` (`pending/`, `wip/`, `done/`). See `_plan_sample_format.md` for the template.
For larger features, a PRD should exist before this plan — link it in the `PRD:` frontmatter field.

---

## Writing style

- **Bullet points only** — no full sentences or prose paragraphs
- Include file paths + line numbers for every code reference
- Keep research findings to: file, trigger, risk level, and why
- Key Decisions: decision, rationale, code location — one subsection per decision
- Code blocks only in API Contracts or a Key Decision where the pattern itself is the point

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
- Buried decisions inside paragraphs — extract as a Key Decision subsection
- Code blocks outside API Contracts or Key Decisions

---

## Plan structure

All plans follow this structure (see `_plan_sample_format.md`):

1. **Frontmatter** — Issue, Branch, Status, PRD link
2. **Problem** — 1-3 bullets: what's broken / missing
3. **Concept** — High-level user-facing behavior
4. **Requirements** — Numbered table
5. **Research** — Bullet-point findings with file paths + line numbers
6. **Root Cause** — Core issue in 1-2 bullets
7. **Architecture** — Single ASCII block diagram showing all components and their connections
8. **Design Details** — CUJs, Data Model, API Contracts, Key Decisions
9. **Files to Modify** — Table: `| File | Change |`
10. **Risks / Open Questions** — Table: `| # | Question | Notes |`
11. **Implementation Phases** — Phased checklist with test verification blocks
12. **Files Summary** — Table mapping file → phase → change

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

## Design Details → Critical User Journeys (CUJs)

CUJs are the first subsection inside **Design Details**. Write one block per distinct user path. Required:

- **Happy path** — the normal success flow, step by step
- **Error / edge-case paths** — at least one (validation failure, auth block, empty state, network error)

CUJ format:
```
User opens [screen]
  → Takes [action]
  → System does X
  → User sees [state]
  → Outcome
```

Rules:
- Use ASCII flow (indented `→`) for the step sequence, not prose
- Follow each flow with 2-3 bullets for error/edge paths
- Cover the paths that drive architectural decisions — don't add CUJs for flows that don't affect design

---

## Design Details → API Contracts

Write one contract block per endpoint or interface boundary:
- REST: method + path, request body, response shape, error codes
- GraphQL: mutation/query name, variables, return type, errors
- RPC / internal service: method name, input type, output type, errors
- Event / message: topic name, payload schema, producer → consumer

Rules:
- Show field names and types — not just "a JSON object"
- List all error codes the caller must handle
- If a contract already exists and isn't changing, say so in one line — don't repeat it

---

## Design Details → Key Decisions

One `####` subsection per decision — applies to both new features and bug fixes.

Topics that typically warrant a Key Decision entry:
- Error handling strategy (retry, fallback, toast, etc.)
- Auth / permission boundary (who can do what, validated where)
- Caching / invalidation (what's cached, when it's stale)
- Offline / sync (supported or not, conflict strategy)
- Concurrency (last-write-wins, optimistic lock, queue)
- Security boundary (what must be validated server-side)
- Rate limiting / quotas (throttle strategy for external calls)
- Observability (what gets logged/metricked on critical paths)

Format:
```markdown
#### Decision N: [Short title]
- **Decision:** what was chosen
- **Rationale:** why (tradeoff / constraint)
- **Where:** `file.ext:line` — what changes
\`\`\`
// optional: only when the code pattern itself is the decision
\`\`\`
```

Rules:
- Every non-trivial design choice gets its own entry — don't bury it in prose
- Code snippet is optional; include only when the pattern wouldn't be clear from the description
- "Where" must have a file path — if it spans files, list each one

---

## Architecture section

The Architecture section is a **single ASCII block diagram** — no prose, no bullets, no decisions. Just components and connections.

```
[Component A] → [Component B] → [Store / DB]
                     ↓
              [Component C] → [UI / Output]
```

Rules:
- One diagram per plan — if you need more, the scope is too large
- Show every major component touched by this feature
- Use `→` for data/control flow, indent for nesting
- No explanatory text inside the section — details belong in Design Details

---

## ASCII flows (CUJs and Key Decisions)

Use `→` flows inside CUJs for user step sequences, and inside Key Decisions when the call/data flow is the decision:

```
User action → Controller → Service → Store commit
                ↓
           UI state → Render
```

- One line per step or level
- Indent for nested steps
- Arrow `→` for "then" or "leads to"

---

## Data Model

Use the table format in the template (Entity / Field / Type / Constraints / Notes). Required:
- Every entity involved in the feature
- Every field being added, changed, or removed
- FK relationships, uniqueness constraints, indexes
- Migration note: Y (what changes + backfill strategy) or N

---

## Checklist before committing a plan

- [ ] Title and first line make scope clear
- [ ] No long paragraphs — bullets and tables only
- [ ] CUJs written for happy path + at least one error path
- [ ] Data Model table present with fields, types, constraints, and migration note
- [ ] API Contracts defined for every new or changed interface
- [ ] Key Decision entry for every non-trivial design choice (error handling, auth, caching, etc.)
- [ ] Every Key Decision has a file path in **Where**
- [ ] Files summary table present (includes test files)
- [ ] ASCII flow used where a sequence matters
- [ ] File paths include line numbers where specific
- [ ] Every phase has a `**Verify phase N:**` block with named, specific test items
- [ ] Test items distinguish unit from integration/regression
