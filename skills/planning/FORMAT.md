# Feature plan format — writing rules

> Read this before writing OR implementing a plan. Per-section templates live in [`SECTIONS.md`](./SECTIONS.md).

Plans live in `.vibekit/feature-plans/<state>/<feature>/`. See `_template_arch.md` /
`_template_plan.md` for templates. For larger features, a PRD should exist
before this plan — link it in the `PRD:` frontmatter field.

---

## Document header block (required)

Every PRD, plan, and sub-plan starts with this block right after frontmatter:

```markdown
<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->
```

- Implementing agent sees the rules on first read — no "didn't know" excuse
- Reviewer verifies compliance immediately

---

## Format rules — allowed elements

| Element | Use for | Example |
|---------|---------|---------|
| Headings (`#`-`####`) | Structure, sections | `## Problem` |
| Bullet lists (`-`) | Findings, steps, options | `- Root cause: X` |
| Numbered lists (`1.`) | Ordered steps, phases | `1. Create schema` |
| Tables | Structured data, comparisons | `\| File \| Change \|` |
| ASCII diagrams | Architecture, flow | `A → B → C` |
| Mermaid blocks | Complex diagrams — see `SECTIONS.md` | `\`\`\`mermaid` |
| Embedded images | Screenshots, visuals | `![alt](./path.png)` |
| Code blocks | API contracts, key decisions | `\`\`\`kotlin` |

## Format rules — banned

- **Prose paragraphs** — any multi-sentence text block without structural markup
- **Verbose requirements** — one line max per requirement; split if longer
- **Inline explanations** — one sentence max; use sub-bullets if more is needed
- File paths + line numbers for every code reference — no vague "the view model"

---

## Checklist rules

- Mark `[ ]` → `[x]` immediately after completing each item — not in a batch at the end
- Commit the updated checklist — progress must persist across sessions
- On resume: scan for the first unchecked `[ ]` — that's the next task
- Never skip items; never mark done before actually done

---

## System boundaries (mandatory when >1 layer is touched)

**Trigger:** the feature touches more than one layer → this section is required, not "if useful".

| Boundary | Must define |
|----------|-------------|
| Frontend ↔ Backend | Endpoint/method, request shape + types, response shape + types, error codes, auth, pagination |
| Client ↔ DB | Table/collection, fields + types, indexes, query patterns, migration + backfill |
| Service ↔ Service | RPC/event name, payload schema, sync vs async, retry + idempotency |
| App ↔ Platform/SDK | Interface the app depends on, what's faked in tests |
| Module ↔ Module (in-process) | Public interface, ownership of state, threading/lifecycle expectations |

**Required per boundary:**
- Named fields with types — never "a JSON object" or "the user data"
- Every error the caller must handle
- Who owns the source of truth
- What happens on failure at that boundary

```
❌ "Frontend fetches the user's saved items from the backend."

✅ GET /api/v1/users/:id/items?cursor=<opaque>&limit=<int:1..100>
     200 { items: Item[], next_cursor: string|null }
     Item { id: uuid, title: string, updated_at: iso8601 }
     401 UNAUTHORIZED · 403 FORBIDDEN · 404 USER_NOT_FOUND
     Auth: Bearer · Source of truth: server · Client cache: stale-while-revalidate
```

- Existing contract that isn't changing → one line saying so; don't restate it
- Contract lives in `Design Details → API Contracts` — covers REST, events, RPC, in-process

---

## Screenshots

- Path: `<subfeature>/screenshots/<descriptive-name>.png`
- Embed with `![alt](./screenshots/name.png)` — descriptive names aid review
- **Default policy: transient** — `screenshots/` is gitignored (`.vibekit/.gitignore`), never committed unless the project sets `screenshots.policy: permanent` in `.vibekit/config.yaml`
- No `.vibekit/config.yaml` present → transient, same as the explicit default
- Cleanup (deleting transient screenshots, rewriting refs) is owned by the `sdlc` skill — see `skills/sdlc/PHASES.md`

---

## Self-containment bar

> Applies to every plan before handoff to a fresh/cheap agent — see the `sdlc` skill → `PHASES.md` § Handoff.

**Litmus test:** could haiku implement this in a fresh session with no other context?

| Check | Test |
|-------|------|
| No pronouns without antecedent | "it" / "the above" / "as discussed" → replaced with the actual noun |
| Every file reference has a path | `path/to/File.ext:123`, not "the view model" |
| Boundary contracts typed | Implementer never has to invent a shape |
| Verification steps runnable verbatim | Exact commands, not "run the tests" |
| No dependency on chat history | A reader who has seen only this file can finish it |

- If the answer to the litmus test is no, the plan is not done — regardless of how complete it looks to the author

---

## Checklist before committing a plan

- [ ] Title and first line make scope clear
- [ ] No long paragraphs — bullets and tables only
- [ ] Header block present, right after frontmatter
- [ ] CUJs written for happy path + at least one error path
- [ ] Data Model table present with fields, types, constraints, and migration note
- [ ] API Contracts / System Boundaries defined for every new or changed interface (required if >1 layer touched)
- [ ] Diagram present where the reader would otherwise hold >3 relationships in their head (see `SECTIONS.md`)
- [ ] Key Decision entry for every non-trivial design choice (error handling, auth, caching, etc.)
- [ ] Every Key Decision has a file path in **Where**
- [ ] Files summary table present (includes test files)
- [ ] File paths include line numbers where specific
- [ ] Every phase has a `**Verify phase N:**` block with named, specific test items
- [ ] Self-containment bar passes — "could haiku implement this cold?"
