# Feature plan format — per-section templates

> Writing rules (header block, banned/allowed elements, checklist, boundaries) live in [`FORMAT.md`](./FORMAT.md). This file covers what each section of the plan contains.

---

## Plan structure

All plans follow this structure (see `_template_arch.md` / `_template_plan.md`):

1. **Frontmatter** — Issue, Branch, Status, PRD link
2. **Problem** — 1-3 bullets: what's broken / missing
3. **Concept** — High-level user-facing behavior
4. **Requirements** — Numbered table
5. **Research** — Bullet-point findings with file paths + line numbers
6. **Architecture Diagram** — boundary diagram (mermaid `flowchart`); one line if single-module
7. **Entities & Modules** — table with public interface column
8. **Architecture** — Single diagram showing all components and connections
9. **Design Details** — CUJs, System Boundaries, Data Model, API Contracts, Key Decisions
10. **Files to Modify** — Table: `| File | Change |`
11. **Risks / Open Questions** — Table: `| # | Question | Notes |`
12. **Implementation Phases** — Phased checklist with test verification blocks
13. **Files Summary** — Table mapping file → phase → change

---

## Implementation phases and test verification

- Every phase ends with a **`Verify phase N:`** block — the phase is not done until those tests pass
- Implementation items: `N.1`, `N.2` … · Test items: `N.T1`, `N.T2` … (T prefix distinguishes them)
- Test files belong in the Files Summary table alongside source files
- "Write tests" without a class name or assertion is not a valid test item — be specific

```markdown
- [ ] **1.T1** Unit — `ClassName`: [specific assertion, e.g. "returns null on empty input"]
- [ ] **1.T2** Integration — `[flow name]`: [trigger → expected outcome]
- [ ] **1.T3** Regression — `[existing flow]`: [behavior that must still pass]
```

| Type | Scope | When to use |
|------|-------|-------------|
| **Unit** | Single class / function in isolation | Pure logic, data transformations, state machines |
| **Integration** | Multiple components or system boundary | Persistence, navigation, real repositories, UI + state |
| **Regression** | Previously passing flow | Any time an existing behavior could be affected by the phase |
---

## Tables

- File changes: `| File | Change |`
- Risk matrix: `| # | Question | Notes |`
- Config/state: `| Variant | Current | Target |`
- Options: `| Option | Pros | Cons |`
- Keep cells short; bullets inside a cell only if needed

---

## Architecture Diagram

- Required whenever the change crosses a module boundary; pure single-module change → one line saying so, no diagram
- Big feature: full system boundary diagram (client/server/DB/3rd-party)
- Small feature: the touched modules + their neighbours only, not the whole system

```mermaid
flowchart LR
    Client -->|POST /items| API
    API --> DB[(Database)]
    API --> Auth[Auth service]
```
---

## Modules & Interfaces (plan) / Entities & Modules (arch)

Declares a **public interface**, not just a dependency list — that's what gets invented badly when missing.
| Module | Responsibility | Public interface | Owns |
|--------|---------------|------------------|------|
| `BackupSerializer` | Config → bytes | `serialize(Config): Result<ByteArray>` | nothing (pure) |
| `RestoreCoordinator` | Apply a backup transactionally | `restore(ByteArray): Result<Unit>` | write lock |
---

## Diagrams — pick what communicates best

- **Goal: make it clear and good-looking.** These are defaults, not a cage — a richer diagram that reads better always wins
- **Rule:** if the reader would hold >3 relationships in their head, draw it
- Name interfaces on the edges — `Client --POST /items--> API`, not `Client --> API`
- Mermaid may use `subgraph`, `classDef`, styling — use them when they aid comprehension

| Intent | Good default | Why |
|--------|-------------|-----|
| System/module boundaries | `mermaid flowchart` + `subgraph` per layer | Renders anywhere; survives renaming |
| Sequence across layers (CUJ) | `mermaid sequenceDiagram` | Shows who calls whom, in order |
| State machine / lifecycle | `mermaid stateDiagram-v2` | Transitions are explicit |
| Entity relationships | `mermaid erDiagram` | Cardinality is explicit |
| Trivial linear flow | ASCII `A → B → C` | Mermaid adds nothing |
| Data shape / field lists | **Table** | Not a diagram — don't draw it |
| Directory layout | ASCII tree | Mermaid does this badly |

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    C->>S: POST /items {title}
    S-->>C: 201 {id}
```

```mermaid
stateDiagram-v2
    [*] --> Pending
    Pending --> Active: approved
    Pending --> Rejected: denied
    Active --> Completed: fulfilled
    Active --> Cancelled: cancelled
    Completed --> [*]
    Cancelled --> [*]
    Rejected --> [*]
```

---

## Design Details → Critical User Journeys (CUJs)

- CUJs are the first subsection inside **Design Details**
- Write one block per distinct user path. Required:

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

**When a snippet earns its place:**
- An ordering constraint, lifecycle trap, concurrency or rollback pattern
- An API shape the implementer would otherwise have to invent
- Not for boilerplate the reader could write from the description alone
- Always comment what the snippet demonstrates — a bare snippet makes the reader guess

Rules:
- Use ASCII flow (indented `→`) for a simple sequence, `mermaid sequenceDiagram` for a multi-layer one
- Follow each flow with 2-3 bullets for error/edge paths
- Cover the paths that drive architectural decisions — don't add CUJs for flows that don't affect design

---

## Design Details → API Contracts

Write one contract block per endpoint or interface boundary — same rules as `FORMAT.md`'s System Boundaries section:
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

- One `####` subsection per decision — applies to both new features and bug fixes
- Typical topics: error handling, auth/permission boundary, caching/invalidation, offline/sync, concurrency, security boundary, rate limiting, observability

Format:
```markdown
#### Decision N: [Short title]
- **Decision:** what was chosen
- **Rationale:** why (tradeoff / constraint)
- **Where:** `file.ext:line` — what changes
\`\`\`
// include when the tricky part is the SHAPE of the code — ordering, lifecycle, easy-to-get-wrong
\`\`\`
```

Rules:
- Every non-trivial design choice gets its own entry — don't bury it in prose
- Code snippet is optional; include only when the pattern wouldn't be clear from the description
- "Where" must have a file path — if it spans files, list each one

---

## Modules vs Data Model — not the same thing

| Section | Answers | Columns |
|---------|---------|---------|
| **Modules & Interfaces** (plan) | what code this change creates/modifies + interfaces it calls | Module, **Change**, Responsibility, Public interface, Owns |
| **Entities & Modules** (arch) | the system's components at design time | Entity/Module, Layer, Responsibility, Interface, Dependencies |
| **Data Model** | what is *persisted* and its shape | Entity, Field, Type, Constraints |

- A module is a unit of behavior; an entity is a unit of storage
- A feature can touch modules and persist nothing, or add a column without a new module
- The plan-side table was called "Entities & Modules" but had no entity column — renamed to **Modules & Interfaces**
- **"Module" is project-relative** — class, package, service, or file, whichever this codebase names in review. Define it once, use it consistently
- **Every row carries a `Change` marker** (`New`/`Modified`/`Unchanged`) — without it the reader cannot tell what is being proposed from what already exists
- Arch keeps `Entity / Module` because a system-level view legitimately lists datastores as components

---

## Architecture section

- Components and connections — **no prose, no decisions** (those belong in Design Details)
- A short legend or one-line component note is fine; a paragraph is not

```mermaid
flowchart LR
  subgraph Client
    UI[Screen] --> VM[ViewModel]
  end
  subgraph Server
    API[/POST /items/] --> SVC[Service]
  end
  VM -- "POST /items" --> API
  SVC --> DB[(Postgres)]
```

Rules:
- **As many diagrams as earn their place** — one is typical; add a sequence or state view when it genuinely helps
- Show every major component this feature touches
- ASCII `→` flows are fine for trivial cases and inside CUJs / Key Decisions

---

## Data Model

Use the table format in the template (Entity / Field / Type / Constraints / Notes). Required:
- Every entity involved in the feature
- Every field being added, changed, or removed
- FK relationships, uniqueness constraints, indexes
- Migration note: Y (what changes + backfill strategy) or N
