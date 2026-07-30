<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# SDLC skill — example usages

> Nine real workflows, with the exact prompt to type and what the agent does with it.

**Quick index**

| # | Situation | Prompt shape |
|---|-----------|--------------|
| [1](#1--start-a-large-feature-from-scratch) | New large feature | `/sdlc <feature>` |
| [2](#2--iterate-on-a-prd-until-edge-cases-are-covered) | PRD needs more rounds | `/sdlc prd <feature>` + follow-ups |
| [3](#3--hand-the-plan-to-a-cheaper-agent) | Delegate to haiku / cursor | `/sdlc handoff <sub-feature>` |
| [4](#4--bugs-found-after-verification) | Impl done, things broken | `/sdlc bugs` |
| [5](#5--revisit-a-plan-after-main-drifted) | Rebase invalidated the plan | `/sdlc replan <sub-feature>` |
| [6](#6--resume-in-a-fresh-session-or-another-cli) | Context died / new terminal | `/sdlc <feature>` |
| [7](#7--park-work-and-come-back-later) | Blocked or deprioritized | `/sdlc park <feature>` |
| [8](#8--write-the-plan-then-wait-for-my-review) | Plan it, but let me review first | `/sdlc plan <feature>` |
| [9](#9--run-prd-plan-and-implementation-but-stop-before-verification) | Everything except verification | `/sdlc prd-plan-implement <feature>` |

---

## 1 — Start a large feature from scratch

**Situation:** New multi-screen feature. Nothing exists yet.

**Prompt:**

```
/sdlc backup-restore

Large feature. Users need to export their whole config to a file and
restore it on another device. Touches settings UI, a new serializer, and
file-picker permissions. Target is Android first, but keep the serializer
platform-agnostic.
```

**What the agent does:**

```
→ asks: large feature (PRD) or small fix?  → you said large, so it skips the question
→ creates .feature-plans/pending/backup-restore/ + .sdlc-state.yaml
→ writes prd-backup-restore.md          → spawns reviewer → incorporates
→ writes plan-backup-restore.md         → spawns reviewer → incorporates
→ proposes decomposition, waits for your OK
→ moves dir to wip/ and starts sub-feature 01
```

**Files after:**

```
.feature-plans/wip/backup-restore/
├── .sdlc-state.yaml
├── prd-backup-restore.md
├── plan-backup-restore.md
├── 01-serializer/plan-01-backup-restore-serializer.md
├── 02-file-picker/plan-02-backup-restore-file-picker.md
└── 03-settings-ui/plan-03-backup-restore-settings-ui.md
```

**Notes:**
- Stating "large feature" up front skips the size question
- Naming the layers ("settings UI, serializer, permissions") drives the decomposition — the agent won't guess as well without it
- Decomposition pauses for your approval; it is not auto-accepted

---

## 2 — Iterate on a PRD until edge cases are covered

**Situation:** The PRD exists but you keep thinking of cases it doesn't handle. You want several rounds before any planning starts.

> **V1 scope:** `/sdlc` ships for Claude Code. Other CLIs read the same plan/state files
> but have no slash command — see example 3 for the paste-ready delegation prompt.

**Prompt (first round):**

```
/sdlc prd backup-restore

Stay on the PRD — do not write a plan yet. I want to keep iterating until
the edge cases are settled. After each round, list what's still unresolved
rather than telling me it looks good.
```

**Follow-up prompts (same session, as many rounds as needed):**

```
What happens on a restore where the backup is from a newer app version?
Add that case and re-review.
```

```
Two more: restore while a sync is mid-flight, and a backup file that's
been truncated. Add both, then have the reviewer look specifically for
cases we're still missing — not general feedback.
```

**Closing the loop when you're satisfied:**

```
Good, edge cases are settled. Lock the PRD and move to planning.
```

**What the agent does:**

```
first round:
  → `prd` is the 1-token chain [prd] → writes prd-backup-restore.md
  → spawns reviewer with focus: "what edge cases are still missing?"
  → chain exhausted → .sdlc-state.yaml:
       master.prd:       pending          (artifact not locked)
       awaiting_phase:   prd              (agent blocked on you)
       awaiting_artifact: <path to prd>
each follow-up round:
  → the prompt names the same artifact → iterates in place
  → awaiting_phase stays `prd` — it never advances to planning
on "lock the PRD" → agent asks you to confirm with /sdlc continue
     only /sdlc continue clears awaiting_*, master.prd = complete → proceeds to plan
```

**Notes:**
- `/sdlc prd <feature>` **is** the 1-token chain `[prd]` — one behavior, two spellings
- The stop is now recorded in the state file, so it survives a context reset — prose alone did not
- **"do not write a plan yet"** still works and remains good practice, but it is no longer what is holding the agent back
- **"list what's still unresolved"** beats "review it" — it forces gaps instead of approval
- PRD iterations are not capped by `max_iterations` when you drive them; the cap applies to automatic review loops
- Point the reviewer at a *specific* axis each round ("cases we're still missing") — a generic re-review returns generic feedback

---

## 3 — Hand the plan to a cheaper agent

**Situation:** Plan is reviewed and good. You want haiku or your cursor agent to implement it, not this session.

**Prompt:**

```
/sdlc handoff 02-file-picker

Check it's self-contained enough for haiku to implement cold — no
references to our conversation, every file path spelled out, the API
between the picker and the serializer fully typed. Tell me what's missing
before I hand it over.
```

**What the agent does:**

```
→ runs the self-containment bar against plan-02-backup-restore-file-picker.md
→ reports per-check pass/fail:
     ✅ every file reference has a path
     ❌ "the serializer interface" — named but not typed
     ❌ step 2.4 says "handle the error case" — no specific behavior
→ offers to fix the two gaps
→ on fix: commits the plan + checklist state
→ prints the handoff summary: what's [x], what's [ ], exact next item
```

**Then, depending on your `runner` config:**

```
# no meta-harness — paste into a fresh session / cursor / gemini
Implement .feature-plans/wip/backup-restore/02-file-picker/plan-02-backup-restore-file-picker.md
fully. Mark each checklist item [x] as you complete it. Start at 2.1.
```

```
# meta-harness present — the agent prints the spawn command for you
ao spawn --cwd <worktree> --model haiku --prompt-file <handoff.md>
```

**Notes:**
- The litmus is **"could haiku do this cold?"** — if the answer is no, the plan isn't finished, however complete it looks to you
- Ask for gaps *before* handing over; a plan that fails cold execution wastes the cheap agent's whole run
- The handoff summary is the thing you paste — no context dump needed
- With a meta-harness configured, the delegated agent gets its **own worktree** and survives this session dying
- Same procedure works when *your* context is nearly full — hand off to a fresh session of yourself

---

## 4 — Bugs found after verification

**Situation:** Sub-feature is implemented, you tried it on device, several things are broken.

**Prompt:**

```
/sdlc bugs

Tried the restore flow on the Pixel. Four problems:
- picker returns a content:// URI we don't handle, restore silently no-ops
- restoring a v2 backup on v3 crashes instead of showing the version error
- progress dialog never dismisses on failure
- back button during restore leaves a half-applied config

Cluster these properly — I don't want four separate plans.
```

**What the agent does:**

```
→ groups by root cause:
     URI handling + half-applied config  → both = no transaction boundary
     version error + progress dialog     → both = error path never surfaces
→ proposes TWO sub-features, not four
→ creates 04-restore-transactions/ and 05-restore-error-paths/
     origin: bug-bundle
     spawned_from: 02-file-picker
→ appends both to the queue
```

**Notes:**
- Reporting all bugs **in one message** is what enables clustering — drip-feeding them one at a time produces one sub-feature each, which is the sprawl you're avoiding
- The agent groups by *root cause*, not by symptom — expect fewer sub-features than bugs
- If you disagree with the grouping, say so; it proposes before creating

---

## 5 — Revisit a plan after main drifted

**Situation:** You rebased, someone landed a big refactor, and the plan's file references are stale.

**Prompt:**

```
/sdlc replan 03-settings-ui

Just rebased on main — there was a big settings refactor. Check whether
the plan is still valid before rewriting it. If the file refs just moved,
update them and keep the plan. Only redo the approach if the refactor
actually invalidated it.
```

**What the agent does:**

```
→ re-resolves every file:line reference in the plan
→ decides:
     refs moved, approach intact   → updates line numbers, keeps plan, no replan
     approach invalidated          → supersedes plan in place, keeps NN=03
                                     adds ## Superseded table (old approach + why)
                                     re-reviews before implementing
→ records superseded_reason in .sdlc-state.yaml
```

**Notes:**
- **"check whether it's still valid before rewriting"** prevents a needless full rewrite — the common case after a rebase is stale line numbers, not a dead approach
- A superseded plan is *rewritten*, not appended to — the stale approach must not linger for the implementer to trip over
- `NN` never changes on a replan; the sub-feature keeps its identity
- If the *goal* changed rather than the approach, that's a new sub-feature — say "add a sub-feature" instead

---

## 6 — Resume in a fresh session or another CLI

**Situation:** Context ran out, terminal died, or you moved to a different worktree/CLI.

**Prompt:**

```
/sdlc backup-restore
```

**That's the whole prompt.** If you want it to be explicit first:

```
/sdlc backup-restore

Just tell me where things stand before doing anything — which sub-feature,
what's done, what's next.
```

**What the agent does:**

```
→ finds .feature-plans/wip/backup-restore/.sdlc-state.yaml
→ verifies cwd matches the `worktree:` field       ← catches wrong-worktree work
→ reads current_subfeature + last_completed
→ reads the plan checklist (checklist wins over state on conflict)
→ restates: "04-restore-transactions, 4.1-4.3 done, next is 4.4"
→ continues from 4.4 — never re-runs a [x] item
```

**Notes:**
- No context dump needed — the committed checklist *is* the resume state
- The worktree check is worth having: work landing in the wrong worktree is a recurring failure
- If an `[x]` item looks wrong, the agent raises it rather than silently redoing it
- **Claude Code only in V1.** In cursor/gemini there is no `/sdlc`, but the state file is plain YAML and the checklist is plain markdown — point any agent at the plan path and it can continue

---

## 7 — Park work and come back later

**Situation:** Blocked on an upstream PR, or priorities moved.

**Prompt:**

```
/sdlc park backup-restore

Blocked until the storage-permissions PR lands upstream. Note that as the
reason so I know why when I come back.
```

**What the agent does:**

```
→ moves .feature-plans/wip/backup-restore/ → pending/
→ records in .sdlc-state.yaml:
     parked_reason: "blocked on upstream storage-permissions PR"
     last_completed: "4.3"
→ leaves the checklist exactly as-is
```

**Coming back, weeks later:**

```
/sdlc backup-restore

The upstream PR landed. Rebase first, then check if the parked plan still
holds before continuing.
```

- Combines resume (#6) with the drift check from replan (#5)

**Notes:**
- Parking is not abandoning — the checklist survives untouched
- `parked_reason` is what future-you reads first; make it specific
- `/sdlc list` shows everything parked in `pending/` with its reason

---

## 8 — Write the plan, then wait for my review

**Situation:** You want the plan written and reviewed, but nothing implemented until you have read it yourself.

**Prompt:**

```
/sdlc plan backup-restore

Small feature, skip the PRD. Write the plan and stop — I want to read it
before anything gets built.
```

**What the agent does:**

```
→ parses `plan` as a 1-token chain (not a feature — no dir named `plan/`)
→ writes plan-backup-restore.md
→ gate: llm (default) → one reviewer pass → incorporates
→ chain exhausted → writes to .sdlc-state.yaml:
     awaiting_phase: plan
     awaiting_artifact: .feature-plans/pending/backup-restore/plan-backup-restore.md
→ reports the path, names `implement` as what comes next, and STOPS
```

**Iterating while it waits — the pause survives every round:**

```
The boundary contract between the serializer and the file picker is still
untyped. Tighten it.
```

```
→ edits the same plan file
→ awaiting_phase stays `plan` — a follow-up on the same artifact never advances
```

**Unblocking it:**

```
/sdlc continue
```

```
→ clears awaiting_*, runs `implement` ONLY, then awaits again at implement
```

**Notes:**
- The stop is a **rule now, not a request** — it is in the state file, so a fresh session or a handoff still honors it
- `/sdlc continue` advances **exactly one** phase — it does not promote you back to the full chain
- Want the human stop on every phase permanently? Set `sdlc.reviewer.gate: user` (or `both`) instead of retyping a chain
- `/sdlc backup-restore` is still a **feature name**, not a chain — `backup` is not a phase token

---

## 9 — Run PRD, plan, and implementation, but stop before verification

**Situation:** You trust the agent through implementation, but you want to run the device verification yourself.

**Prompt:**

```
/sdlc prd-plan-implement backup-restore

Go all the way through implementation, then stop. The Pixel is busy and I
want to run the verification pass myself.
```

**What the agent does:**

```
→ every `-` segment is a phase token → chain = [prd, plan, implement]
→ prd-backup-restore.md   → reviewer → incorporates
→ plan-backup-restore.md  → reviewer → incorporates
→ works the checklist, marking [x] as it goes
→ chain exhausted → awaiting_phase: implement
→ does NOT run tests and does NOT touch a device
```

**Equivalent with the other separator:**

```
/sdlc prd+plan+implement backup-restore
```

**Notes:**
- `+` and `-` are interchangeable — pick whichever reads better
- Order does not matter: `/sdlc implement+plan <f>` runs plan first, and **says so before writing anything**
- Skipping a phase is allowed (`/sdlc prd+implement`) but you get one warning — it usually means you forgot `plan`
- The chain end stops even though `gate` is the default `llm` and the reviewer was clean

---

## Discovery — the two commands you type first

```
/sdlc status
```
```
backup-restore  (wip)
  03-fix-nav-regressions   mode: implementing   origin: bug-bundle (from 02-api)
  checklist: 6/11 [x]      next: 2.4 — wrap restore in a transaction
  runner: in-harness (vibe-station detected — set runner.meta_harness to delegate)
```

```
/sdlc list
```
```
wip/      backup-restore        3 sub-features   current: 03-fix-nav-regressions
pending/  offline-mode          1 sub-feature    PARKED: blocked on sync refactor
done/     onboarding-revamp     2 sub-features
```

---

## Prompt patterns worth reusing

| Want | Say | Not |
|------|-----|-----|
| More PRD rounds | "do not write a plan yet" | "review the PRD" |
| Real gaps | "list what's still unresolved" | "does this look good?" |
| Fewer sub-features | report all bugs in one message | one bug per message |
| Keep a valid plan | "check if it's still valid before rewriting" | "update the plan" |
| Cheap-agent-ready | "check it's self-contained for haiku" | "is the plan done?" |
| Targeted review | "look specifically for X" | "review again" |
| Scope one invocation | `/sdlc plan <f>` or `/sdlc prd+plan <f>` | "just do the plan for now" |
| Stop on every phase, always | `sdlc.reviewer.gate: user` in `.vibekit.yaml` | retyping a chain each time |

## Things the agent will not do without being asked

- Commit or push — always asks first
- Use a physical device — asks whether it's free (devices are shared across sessions)
- Advance PRD → plan while you're still iterating, if you said not to
- Widen scope silently — a large new requirement becomes its own sub-feature
- Delete screenshots without confirmation, even though transient is the default
