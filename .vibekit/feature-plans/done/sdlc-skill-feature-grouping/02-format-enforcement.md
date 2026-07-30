# Mini-Design: Plan Format Enforcement + Screenshot Config

> Enforce bullet/table/visual-only format in plans (no prose paragraphs) and add configurable screenshot lifecycle (transient vs permanent).

**Issue:** upgrade-to-sdlc-nfeaturegrouping-jul26
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26`
**Status:** Pending
**Parent design:** `./plan-sdlc-skill-feature-grouping.md`

**Reference files:**
- Planning format rules: `skills/planning/FORMAT.md` _(currently `AGENTS.md`; renamed in Phase 0)_
- PRD SKILL.md: `skills/prd/SKILL.md`
- Plan templates: `skills/planning/_plan_sample_*.md`

---

## Problem

- Plan format allows drift into prose paragraphs — inconsistent with bullet-point intent
- PRD requirements are verbose — multi-sentence descriptions instead of crisp one-liners
- No explicit rule banning paragraphs in the planning writing-style section
- Implementing agents don't mark checklist items — no persistent progress tracking
- Device verification screenshots have no lifecycle — accumulate or are lost
- No config mechanism for screenshot policy (transient vs permanent)
- **Cross-layer boundaries left undefined** — plan touches frontend + backend but never pins the API contract; implementer invents one, often unscalable
- Same gap for client↔DB (schema/query shape) and service↔service boundaries

## Out of Scope

- SDLC orchestration (handled in 03-sdlc-orchestration.md)
- Directory structure changes (handled in 01-directory-structure.md)
- Reviewer model configuration (handled in 03-sdlc-orchestration.md)

## Concept

- Strengthen planning format rules to explicitly ban prose paragraphs
- Define allowed elements: headings, bullets, numbered lists, tables, ASCII diagrams, mermaid, embedded images
- Add `.vibekit.yaml` schema for screenshot policy
- SDLC skill reads config and executes cleanup before PR

## Requirements

| # | Requirement |
|---|-------------|
| 1 | **All docs:** bullets, tables, code, diagrams ONLY — no prose paragraphs anywhere |
| 2 | **PRD requirements:** one crisp line each — no multi-sentence descriptions |
| 3 | **Checklist discipline:** implementing agent MUST mark `[x]` on completion |
| 4 | **Header block:** every doc starts with rules reminder (visible to implementing agent) |
| 5 | Allowed elements enumerated: headings, bullets, tables, ASCII, mermaid, code, images |
| 6 | **Boundary contracts mandatory:** every cross-layer boundary the feature touches gets a defined interface in the plan |
| 7 | Boundary section is not optional — plan is incomplete without it if >1 layer is touched |
| 8 | Screenshots default to **transient** — never committed unless explicitly configured |
| 9 | `screenshots/` is gitignored by default; `permanent` policy is opt-in per project |
| 10 | **Companion files named by role**, not by convention — `AGENTS.md` retired as a skill filename |
| 11 | **Every companion file is linked from SKILL.md** — an unlinked file is never loaded |
| 12 | Maintainer-only docs live in `CONTRIBUTING.md` and are excluded from adapter installs |
| 13 | **Both** templates carry System Context + Entities & Modules — not just the big one |
| 14 | Module tables declare a **public interface**, not just dependencies |
| 15 | Diagram type is prescribed per intent; mermaid examples exist to copy from |

---

## Research

### Current planning format rules

- **File:** `skills/planning/FORMAT.md:10-15`
- **Current:** "Bullet points only — no full sentences or prose paragraphs"
- **Gap:** Rule exists but not emphasized; allowed elements not enumerated
- **Risk:** LOW — strengthening existing rule

### PRD skill actively mandates prose — DIRECT CONFLICT

- **File:** `skills/prd/SKILL.md:42` — "PRDs use **full sentences and prose in requirements**"
- **File:** `skills/prd/FORMAT.md:9` — "PRDs are **prose-first** — opposite of the technical plan"
- **File:** `skills/prd/FORMAT.md:13` — Do/Don't table: *Do* "Full sentences for requirements" / *Don't* "Bullet-only fragments"
- **File:** `skills/prd/FORMAT.md:29,49` — requirements template specifies "prose descriptions" / "Full sentence describing…"
- **Conflict:** master F5/F6 ban prose in ALL docs including PRDs
- **Resolution:** prose-first rule is **inverted**, not exempted — these lines must be rewritten
- **Risk:** HIGH — leaving them means the PRD skill instructs the opposite of the header block on the same file

### Templates under-serve boundaries and diagrams

| Section | Big template | Small template | Gap |
|---------|:---:|:---:|-----|
| System Context (boundary diagram) | ✅ `:52` | ❌ | Most work is sub-feature-sized → this view is rarely seen |
| Entities & Modules (responsibility table) | ✅ `:76` | ❌ | Module ownership undefined at the level people work at |
| API / Contract | ✅ `:100` | ✅ `:114` | REST-shaped only; no events/RPC/in-process |
| Data Model | ✅ `:127` | ✅ `:102` | — |
| CUJs | ✅ `:142` | ✅ `:78` | — |
| Architecture diagram | — | ✅ `:66` (single ASCII) | No guidance on when a diagram is required |

- **Mermaid: zero occurrences anywhere in `skills/`** — every template diagram is ASCII
- Format rules *permit* mermaid, but agents copy the template, so they will keep emitting ASCII
- **Consequence:** the two sections that make a design readable (System Context, Entities & Modules) are absent exactly where most plans are written
- **Risk:** MEDIUM — boundary contracts alone don't fix readability if no diagram is ever produced

### `AGENTS.md` conflates two audiences — and two of three are never loaded

| Skill | `AGENTS.md` actually contains | Audience | Linked from SKILL.md? |
|-------|-------------------------------|----------|----------------------|
| `planning` (235 ln) | Output format rules | Agent **using** the skill | ✅ `SKILL.md:47` |
| `prd` (125 ln) | Output format rules | Agent **using** the skill | ❌ never referenced |
| `android-coding` (40 ln) | "What belongs in this skill" | vibekit **maintainer** | ❌ never referenced |
| `guardrails` | absent | — | — |

- **SKILL.md is the entry point** — a sibling file nothing links gives the agent no reason to open it
- **Consequence:** `prd/AGENTS.md`'s format rules are almost certainly dead weight — plausibly why PRD verbosity persisted despite documented rules
- **Consequence:** `android-coding/AGENTS.md` is contributor documentation that currently ships into every user's `~/.claude/skills/`
- `planning/AGENTS.md` is **235 lines**, violating `guardrails/SKILL.md:23` (200-line cap on agent guide files) — the skill breaks its own rule
- **Risk:** HIGH — inverting PRD prose rules in a file the agent never reads would be a no-op fix

### What survives the inversion

- PRDs still describe **user-facing behavior**, not implementation — that distinction is orthogonal to prose
- PRDs still carry **no file paths, no code references** — unchanged
- Only the *prose requirement* changes: a requirement stays behavioral but becomes one crisp line

---

## Architecture

```
skills/planning/FORMAT.md
    │
    └── (UPDATE) Format Rules section
         ├── Explicit NO: multi-sentence paragraphs
         ├── Explicit YES: headings, bullets, tables, ASCII, mermaid, images
         └── Screenshot embedding rules

.vibekit.yaml (project root)
    │
    └── (NEW) screenshots config block
         ├── policy: transient | permanent
         └── path: screenshots/

skills/sdlc/SKILL.md (created in 03)
    │
    └── References screenshot config
         └── Cleanup step before PR
```

---

## Design Details

### Critical User Journeys (CUJs)

#### CUJ 1 — Agent writes plan with screenshots

```
Agent implements feature
  → Takes device screenshot during verification
  → Saves to .feature-plans/wip/auth-flow/02-api/screenshots/step-3-login.png
  → References in plan: `![Login state](./screenshots/step-3-login.png)`
  → Plan review proceeds with visual context
```

- **Error path:** screenshot save fails → log warning, continue without image
- **Edge case:** no screenshots taken → screenshots/ directory not created

#### CUJ 2 — Transient screenshot cleanup

```
Agent completes feature
  → Reads .vibekit.yaml: screenshots.policy = transient
  → Deletes .feature-plans/wip/auth-flow/02-api/screenshots/ directory
  → Removes image references from plan (or replaces with "[screenshot removed]")
  → Commits clean plan
  → Creates PR
```

#### CUJ 3 — Permanent screenshots

```
Agent completes feature
  → Reads .vibekit.yaml: screenshots.policy = permanent
  → Screenshots directory remains
  → Images committed to repo
  → PR includes visual documentation
```

### Key Decisions

#### Decision 0: Skill companion files named by role, always linked

- **Decision:** Retire `AGENTS.md` as a skill filename. Companion files are named for their content and **must** be linked from SKILL.md. `CONTRIBUTING.md` is reserved for maintainer docs and excluded from installs.
- **Rationale:** One filename currently means two opposite audiences; two of three instances are unlinked and therefore never loaded
- **Where:** `CLAUDE.md` repo layout; applied across all skills

| File | Role | Loaded when | Ships |
|------|------|-------------|-------|
| `SKILL.md` | Entry point — always read | Skill invoked | ✅ |
| `FORMAT.md` | Output format rules (`planning`, `prd`) | SKILL.md links it | ✅ |
| `PHASES.md` | Per-phase agent behavior (`sdlc`) | SKILL.md links it | ✅ |
| `CONTRIBUTING.md` | "What belongs in this skill" — maintainers | Never by agents | ❌ excluded |

**Rules:**
- A skill needs a companion only if it produces a document with a format, or has multi-phase behavior
- Pure rule skills (`coding-agent-guardrails`, `coding`, `android-coding`) need **no** companion — SKILL.md is the whole skill
- Every companion is linked from SKILL.md with a one-line "read this before X" pointer
- Unlinked companion = dead file; the reviewer flags it

**Renames:**

| From | To |
|------|-----|
| `skills/planning/AGENTS.md` | `skills/planning/FORMAT.md` (+ split, see Decision 0b) |
| `skills/prd/AGENTS.md` | `skills/prd/FORMAT.md` |
| `skills/android-coding/AGENTS.md` | `skills/android-coding/CONTRIBUTING.md` |

#### Decision 0b: Split planning FORMAT.md under the 200-line cap

- **Decision:** Split the 235-line planning guide into `FORMAT.md` (writing rules) + `SECTIONS.md` (per-section templates)
- **Rationale:** `coding-agent-guardrails/SKILL.md:23` caps agent guide files at 200 lines; the planning guide currently violates it
- **Where:** `skills/planning/FORMAT.md`, `skills/planning/SECTIONS.md`, both linked from SKILL.md

#### Decision 1: Document header block

- **Decision:** Every PRD/plan/sub-plan starts with a rules reminder block
- **Rationale:** Implementing agent sees rules immediately; no "didn't know" excuse
- **Where:** All template files; enforced by reviewer

```markdown
<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions  
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->
```

#### Decision 2: Explicit format whitelist

- **Decision:** Enumerate allowed elements; explicitly ban unstructured text blocks
- **Rationale:** Agents need unambiguous rules; "bullet points only" is too vague
- **Where:** `skills/planning/FORMAT.md:10-35` — expand Format Rules section

```markdown
## Format Rules — Allowed Elements

| Element | Use for | Example |
|---------|---------|---------|
| Headings (`#`-`####`) | Structure, sections | `## Problem` |
| Bullet lists (`-`) | Findings, steps, options | `- Root cause: X` |
| Numbered lists (`1.`) | Ordered steps, phases | `1. Create schema` |
| Tables | Structured data, comparisons | `| File | Change |` |
| ASCII diagrams | Architecture, flow | `A → B → C` |
| Mermaid blocks | Complex diagrams | `\`\`\`mermaid` |
| Embedded images | Screenshots, visuals | `![alt](./path.png)` |
| Code blocks | API contracts, key decisions | `\`\`\`kotlin` |

## Format Rules — Banned

- **Prose paragraphs** — any multi-sentence text block without structural markup
- **Verbose requirements** — one line max per requirement; split if longer
- **Inline explanations** — keep to one sentence max; use sub-bullets if more needed
```

#### Decision 3: Checklist discipline

- **Decision:** Implementing agent MUST mark `[x]` on each completed item
- **Rationale:** Persistent progress; acts as todo list for agent resume
- **Where:** `skills/planning/FORMAT.md` (this sub-plan); the SDLC-side resume rule is `03` Phase 2.2

```markdown
## Checklist Rules

- Mark `[ ]` → `[x]` immediately after completing each item
- Commit the updated checklist — progress must persist across sessions
- On resume: scan for first unchecked `[ ]` — that's your next task
- Never skip items; never mark done before actually done
```

#### Decision 4: Mandatory boundary contracts

- **Decision:** Plan MUST define an interface for every cross-layer boundary the feature crosses
- **Rationale:** Undefined boundary → implementer invents one → unscalable shape baked in before review catches it
- **Where:** `skills/planning/FORMAT.md` — new "System Boundaries" section; `_plan_sample_*.md` — required section

**Trigger:** if the feature touches more than one layer, the section is required — not "if useful".

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
- Contract lives in the plan's `Design Details → API Contracts` (extended to cover all boundary types, not just REST)

#### Decision 4b: Every plan carries a System Context diagram

- **Decision:** Add `## System Context` to the **small** template too, scaled to sub-feature size. Required whenever the change crosses a module boundary.
- **Rationale:** It's the section that makes a design readable at a glance; today it exists only in the big template, which is the rarer case
- **Where:** `_plan_sample_small_feature_bugfix.md` — new section before `## Architecture`

- Small-template version: the touched modules + their neighbours, not the whole system
- Pure single-module change → one line saying so, no diagram

#### Decision 4c: Diagram type is prescribed, not left to taste

- **Decision:** Table mapping intent → diagram type, with a mermaid example for each
- **Rationale:** Mermaid appears **zero times** in `skills/` today; agents copy templates, so without worked examples they will keep emitting ASCII regardless of what the rules permit
- **Where:** `skills/planning/SECTIONS.md` — new Diagrams section; examples in both templates

| Intent | Use | Why |
|--------|-----|-----|
| System/module boundaries | `mermaid flowchart` | Renders in GitHub/editors; survives renaming |
| Sequence across layers (CUJ) | `mermaid sequenceDiagram` | Shows who calls whom, in order |
| State machine / lifecycle | `mermaid stateDiagram-v2` | Transitions are explicit |
| Simple linear flow (≤4 nodes) | ASCII `A → B → C` | Mermaid is overkill |
| Data shape / field lists | **Table** | Not a diagram — don't draw it |
| Directory layout | ASCII tree | Mermaid can't do this well |

- One rule: **if the reader would have to hold >3 relationships in their head, draw it**
- Interfaces are named on the edges — `Client --POST /items--> API`, not `Client --> API`

#### Decision 4d: Module interfaces are declared, not implied

- **Decision:** `## Entities & Modules` added to the small template — module, responsibility, public interface, owner of state
- **Rationale:** The existing table (big template `:76`) lists dependencies but not the *interface*; that's what an implementer invents badly when it's missing
- **Where:** both templates; `SECTIONS.md`

| Module | Responsibility | Public interface | Owns |
|--------|---------------|------------------|------|
| `BackupSerializer` | Config → bytes | `serialize(Config): Result<ByteArray>` | nothing (pure) |
| `RestoreCoordinator` | Apply a backup transactionally | `restore(ByteArray): Result<Unit>` | write lock |

#### Decision 5: Screenshot path convention

- **Decision:** `<subfeature>/screenshots/<descriptive-name>.png`
- **Rationale:** Predictable location; descriptive names aid review
- **Where:** `skills/planning/FORMAT.md` — new Screenshots section

#### Decision 6: Screenshots are transient by default, never committed

- **Decision:** Default `policy: transient`; `screenshots/` gitignored; `permanent` is explicit opt-in
- **Rationale:** Safe default — a missing/absent config must never result in binaries landing in git history (unrecoverable without a rewrite)
- **Where:** `scaffold.sh` writes the ignore rule (this sub-plan); SDLC-side defaults live in `03` Phase 1.2

```gitignore
# .feature-plans/.gitignore — written by scaffold.sh
**/screenshots/
```

- `permanent` policy → project removes/narrows the ignore rule deliberately
- No `.vibekit.yaml` present → transient (never commit), same as explicit default
- Cleanup still prompts before deleting, so review is possible before they're gone

#### Decision 7: Transient cleanup mechanism

- **Decision:** SDLC skill deletes directory + rewrites markdown references to `[screenshot: <name> — removed]`
- **Rationale:** Agent-driven cleanup ensures consistent behavior; no broken image links
- **Where:** `skills/sdlc/SKILL.md` (created in 03) — cleanup phase

---

## Files to Modify

| File | Change |
|------|--------|
| `skills/planning/FORMAT.md` | Format whitelist/banned; checklist rules; header block |
| `skills/planning/_plan_sample_small_feature_bugfix.md` | Add header block + screenshot example |
| `skills/planning/_plan_sample_big_feature_design.md` | Add header block |
| `skills/prd/SKILL.md` | Add crisp requirements rule; ban verbose descriptions |
| `skills/prd/FORMAT.md` | Create — format rules for PRD writing |
| `skills/prd/_prd_sample_format.md` | Add header block; tighten requirement examples |
| `.vibekit.yaml.example` | Create example config file |

## Risks / Open Questions

| # | Question | Notes |
|---|----------|-------|
| 1 | **What if no .vibekit.yaml exists?** | Default to `transient` — safer for repo size |
| 2 | **How to handle broken image refs after cleanup?** | Replace with `[screenshot: <name> — removed]` |
| 3 | **Image formats?** | Allow PNG, JPG, GIF, WebP; prefer PNG for screenshots |
| 4 | **Image size limits?** | Recommend max 1920px width; document but don't enforce in V1 |
| 5 | **Screenshot capture mechanism?** | Left to agent — Android: adb, Browser: chrome tools, Desktop: native |

---

## Implementation Phases

### Phase 0 — Retire `AGENTS.md`; rename companions by role

- [x] **0.1** `git mv skills/planning/AGENTS.md skills/planning/FORMAT.md`
- [x] **0.2** Split `FORMAT.md` → `FORMAT.md` (writing rules) + `SECTIONS.md` (per-section templates), each < 200 lines
- [x] **0.3** `git mv skills/prd/AGENTS.md skills/prd/FORMAT.md`
- [x] **0.4** `git mv skills/android-coding/AGENTS.md skills/android-coding/CONTRIBUTING.md`
- [x] **0.5** Add link in `skills/planning/SKILL.md` to both `FORMAT.md` and `SECTIONS.md`
- [x] **0.6** Add link in `skills/prd/SKILL.md` to `FORMAT.md` — it currently references **no** companion
- [x] **0.7** Document the companion-file convention in `CLAUDE.md` repo layout
- [x] **0.8** **Update `scaffold.sh:27` copy list** `AGENTS.md` → `FORMAT.md` (+ decide if `SECTIONS.md` ships to projects)
- [x] **0.9** **Update `scaffold.sh:64` emitted text** `.feature-plans/AGENTS.md` → `.feature-plans/FORMAT.md`
- [x] **0.10** Add skip-guard to `adapters/cursor/install.sh:26` + `adapters/gemini/install.sh:28`: a dir with no `SKILL.md` is SKIPPED, not fatal

**Verify phase 0:**
- [x] **0.T1** Integration — `find skills -name AGENTS.md` returns zero results
- [x] **0.T2** Integration — every companion file is reachable from its SKILL.md: `grep -l FORMAT.md skills/*/SKILL.md` lists `planning` and `prd`
- [x] **0.T3** Integration — `wc -l skills/planning/FORMAT.md skills/planning/SECTIONS.md` both < 200
- [x] **0.T4** Manual — No content lost in the split; every rule from the original 235 lines has a home
- [x] **0.T5** Integration — `bash skills/planning/scaffold.sh $(mktemp -d)` still exits 0 AFTER the rename
- [x] **0.T6** Integration — generated project guide references `FORMAT.md`, not `AGENTS.md`
- [x] **0.T7** Integration — `mkdir skills/_probe && ./install.sh cursor all /tmp/t` skips it and still installs every real skill

---

### Phase 1 — Add header block + format rules to planning skill

- [x] **1.1** Add header block template to `skills/planning/FORMAT.md`
- [x] **1.2** Add "Format Rules — Allowed Elements" table
- [x] **1.3** Add "Format Rules — Banned" section (prose, verbose, etc.)
- [x] **1.4** Add "Checklist Rules" section — mark `[x]` on completion
- [x] **1.5** Add header block to `_plan_sample_small_feature_bugfix.md`
- [x] **1.6** Add header block to `_plan_sample_big_feature_design.md`

**Verify phase 1:**
- [x] **1.T1** Manual — Read `FORMAT.md`; rules are unambiguous
- [x] **1.T2** Manual — Both templates have header block at top

---

### Phase 2 — Invert PRD prose-first rule

> `skills/prd/FORMAT.md` **already exists** and mandates prose. This phase rewrites it, not creates it.

- [x] **2.1** Rewrite `skills/prd/SKILL.md:42` — replace "full sentences and prose" with one-crisp-line-per-requirement
- [x] **2.2** Rewrite `skills/prd/FORMAT.md:9` — drop "prose-first"; state behavioral-but-structured
- [x] **2.3** Invert `skills/prd/FORMAT.md:13` Do/Don't table rows about full sentences
- [x] **2.4** Update `skills/prd/FORMAT.md:29,49` requirement templates to one-line format
- [x] **2.5** Preserve the behavioral/no-file-paths rules — those are unrelated to prose
- [x] **2.6** Add header block + rewrite verbose examples in `_prd_sample_format.md`

**Verify phase 2:**
- [x] **2.T1** Manual — `grep -rn -i "prose-first\|full sentences" skills/prd/` returns zero hits
- [x] **2.T2** Manual — Every sample requirement in `_prd_sample_format.md` is one line
- [x] **2.T3** Manual — "no file paths / no code references" rules still present

---

### Phase 3 — System boundaries section

- [x] **3.1** Add "System Boundaries" section to `skills/planning/FORMAT.md`
  - Boundary-type table (frontend↔backend, client↔DB, service↔service, module↔module)
  - Required-per-boundary list (typed fields, errors, source of truth, failure mode)
  - ❌/✅ example
- [x] **3.2** Add required `## System Boundaries` section to `_plan_sample_small_feature_bugfix.md`
- [x] **3.3** Add same to `_plan_sample_big_feature_design.md`
- [x] **3.4** Extend `Design Details → API Contracts` guidance to cover non-REST boundaries (events, RPC, in-process)
- [x] **3.5** Add `## System Context` to the **small** template, scaled to sub-feature size
- [x] **3.6** Add `## Entities & Modules` to the small template with a **public interface** column
- [x] **3.7** Add the interface column to the big template's existing Entities & Modules table
- [x] **3.8** Add Diagrams section to `SECTIONS.md`: intent→type table + one worked mermaid example each
- [x] **3.9** Convert one template diagram to mermaid so agents have a copyable pattern
- [x] **3.10** Add boundary + diagram checks to the `FORMAT.md` pre-commit checklist

**Verify phase 3:**
- [x] **3.T1** Manual — `FORMAT.md` states the section is mandatory when >1 layer is touched
- [x] **3.T2** Manual — Both templates carry the section with typed-field examples
- [x] **3.T3** Integration — `grep -c mermaid skills/planning/*.md` > 0 (was 0 across all of `skills/`)
- [x] **3.T4** Manual — Small template has System Context + Entities & Modules with interfaces
- [x] **3.T5** Manual — Diagram table says which type to use and when NOT to draw one

---

### Phase 4 — Screenshot defaults + gitignore

> `skills/sdlc/*` does not exist until 03 — the "no config → transient" fallback and the
> cleanup mechanism are documented there, not here. This phase owns only the format/config side.

- [x] **4.1** Create `.vibekit.yaml.example` with `screenshots.policy: transient` as documented default
- [x] **4.2** Update `scaffold.sh` to write `.feature-plans/.gitignore` with `**/screenshots/`
- [x] **4.3** Add screenshot embedding example to plan template (path: `<subfeature>/screenshots/`)
- [x] **4.4** Update CLAUDE.md with config documentation

**Verify phase 4:**
- [x] **4.T1** Integration — Scaffold temp dir; `touch .feature-plans/wip/f/01-x/screenshots/a.png`; `git check-ignore` matches
- [x] **4.T2** Manual — `.vibekit.yaml.example` is valid YAML with transient default
- [x] **4.T3** Manual — Docs state screenshots are never committed unless opted in

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `skills/planning/FORMAT.md` | 1.1-1.4, 3.1, 3.5 | Header block, format rules, checklist rules, boundaries |
| `_plan_sample_small_feature_bugfix.md` | 1.5, 3.2, 3.5-3.6, 4.3 | Header block, boundaries, System Context, Entities & Modules |
| `_plan_sample_big_feature_design.md` | 1.6, 3.3, 3.7, 3.9 | Header block, boundaries, interface column, mermaid |
| `skills/prd/SKILL.md` | 2.1 | Crisp requirements rule |
| `skills/prd/FORMAT.md` | 2.2 | New — PRD format rules |
| `_prd_sample_format.md` | 2.3-2.4 | Header block + crisp examples |
| `.vibekit.yaml.example` | 4.1 | Config template, transient default |
| `skills/planning/scaffold.sh` | 4.2 | Write `.feature-plans/.gitignore` |

| `CLAUDE.md` | 4.4 | Config documentation |
