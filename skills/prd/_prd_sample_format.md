# PRD: [Feature Name]

> One sentence describing the feature and its scope.

**Status:** Draft | Review | Approved | Superseded
**Technical plan:** `.feature-plans/pending/<slug>.md` _(link once the plan exists)_

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

One sentence orienting the reader on what this section covers.

| ID | Requirement |
|----|-------------|
| R1 | Full sentence describing observable user-facing behavior. Specific enough to be testable. |
| R2 | Constraint or non-functional requirement (performance, accessibility, gating). |
| R3 | Edge case or error state that must be handled explicitly. |

### 2. [Second Feature Area]

One sentence orienting the reader.

| ID | Requirement |
|----|-------------|
| R4 | Requirement sentence. |
| R5 | Requirement sentence. |

### 3. [Back Navigation / State Management] _(include if the feature has multi-step flows)_

| ID | Requirement |
|----|-------------|
| R6 | Back from step N returns to step N-1 without losing state. |
| R7 | Cancelling the flow at any step discards in-progress changes. |

---

## Options considered

### [Decision area name]

**Option A — [Name] (chosen)**
Description of the approach. What the user experiences. Key trade-off.

**Option B — [Name]**
Description of the alternative. Why it was not chosen.

**Decision:** Option A because [concise rationale].

---

_Use a table when there are more than two options or multiple attributes to compare:_

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| A — name | Advantage | Disadvantage | ✅ chosen |
| B — name | Advantage | Disadvantage | ❌ deferred |

---

## Resolved design questions

_Record every decision made during PRD review. Do not reopen these in the technical plan._

1. **Question?** — **Answer.** Rationale in one sentence.
2. **Question?** — **Answer.** Rationale in one sentence.
3. **Question?** — **Answer.** Rationale in one sentence.

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
