<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# PRD: [Feature Name]

> One sentence describing the feature and its scope.

**Status:** Draft | Review | Approved | Superseded
**Technical plan:** `.feature-plans/pending/<feature>/plan-<feature>.md` _(link once the plan exists)_

---

## Problem

- What's broken or missing today (1–3 bullets)
- Who is affected and how
- Why this matters now

## Goals

- What success looks like from the user's perspective
- Key metrics or observable outcomes if applicable

## Non-goals

- Explicitly out of scope for this version
- Future considerations that are deferred (note them, don't spec them)

---

## Requirements

### 1. [Primary Feature Area]

| ID | Requirement |
|----|-------------|
| R1 | User taps [action] → sees [result] within [Nms]. |
| R2 | Performance / accessibility / gating constraint, one line. |
| R3 | Edge case or error state, one line. |

### 2. [Second Feature Area]

| ID | Requirement |
|----|-------------|
| R4 | Requirement, one line. |
| R5 | Requirement, one line. |

### 3. [Back Navigation / State Management] _(include if the feature has multi-step flows)_

| ID | Requirement |
|----|-------------|
| R6 | Back from step N returns to step N-1 without losing state. |
| R7 | Cancelling the flow at any step discards in-progress changes. |

---

## Options considered

### [Decision area name]

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| A — [Name] | Advantage, one line | Disadvantage, one line | ✅ chosen |
| B — [Name] | Advantage, one line | Disadvantage, one line | ❌ deferred |

**Decision:** Option A because [one-line rationale].

---

## Resolved design questions

_Record every decision made during PRD review. Do not reopen these in the technical plan._

1. **Question?** — **Answer.** One-line rationale.
2. **Question?** — **Answer.** One-line rationale.
3. **Question?** — **Answer.** One-line rationale.

---

## Screen layouts

_One ASCII diagram per new screen or significantly changed state. Annotate non-obvious zones._

### [Screen Name]

```
┌──────────────────────────────────┐
│  Screen Title                    │  ← header / nav bar
│                                  │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  │   [Main content area]      │  │  ← ~60% screen height
│  │                            │  │    describe behavior
│  │                            │  │
│  └────────────────────────────┘  │
│                                  │
│  Supporting text or metadata     │  ← spotlight / description zone
│                                  │
│  ┌──────────────────────────┐   │
│  │    Primary CTA           │   │  ← primary action
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │    Secondary CTA         │   │  ← secondary / cancel
│  └──────────────────────────┘   │
└──────────────────────────────────┘
```

Notes:
- What happens when the primary CTA is tapped
- What happens when the secondary CTA is tapped
- Any state-dependent UI changes (e.g., CTA label changes based on selection)

---

## Priority & sequencing

_Include only when the feature has sub-parts that must ship in a specific order._

| Order | Sub-feature | Depends on | Can ship independently? |
|-------|-------------|------------|------------------------|
| 1 | [Core sub-feature] | — | Yes |
| 2 | [Dependent sub-feature] | Sub-feature 1 | No |
| 3 | [Optional enhancement] | Sub-feature 1 | Yes |

---

## Open questions

_Items that are still unresolved. Each should have a proposed answer or a named owner._

| # | Question | Proposed answer / owner |
|---|----------|------------------------|
| 1 | **Short question?** | Proposed answer or @owner |
| 2 | **Short question?** | Proposed answer or @owner |
