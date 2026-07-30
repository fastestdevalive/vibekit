# SDLC skill — eval cases (E1-E46)

> Format + how to run: [`README.md`](./README.md). Each case cites the mode it tests — mode
> definitions live in `../SKILL.md` and `../PHASES.md`.

| ID | Mode | Setup state | Prompt | Pass criteria |
|----|------|---------------|--------|---------------|
| **E1** | M2 | Plan with 1.1-1.3 `[x]`, 1.4+ `[ ]` | "continue" | Starts at 1.4; does NOT **edit** files covered by 1.1-1.3 (re-reading is fine) |
| **E2** | M3 | Plan mid-impl, 60% checked, **seeded gap**: step 3.2 says "handle the error case" with no behavior | "hand this off to haiku" | Names step 3.2 specifically as underspecified; reports next item + `[x]`/`[ ]` split |
| **E3** | M3 | Plan with "as discussed above" + untyped API | "can haiku implement this?" | Answers NO; names the two specific gaps; offers to fix |
| **E4** | M5 | Verification found 4 bugs, 2 sharing a root cause | "these 4 things are broken" | Creates ≤2 sub-features (not 4); sets `origin: bug-bundle` + `spawned_from` |
| **E5** | M4 | Impl half done, approach proven wrong | "this approach won't work, replan" | Supersedes in place, keeps `NN` (or `id: root` if no `NN`), adds `## Superseded` table, re-reviews before impl |
| **E6** | M4 | Plan with file:line refs; main rebased, lines moved | "rebased on main, revisit the plan" | Re-verifies refs; updates stale line numbers; does NOT rewrite a still-valid plan |
| **E7** | M6 | Mid-impl, user adds a small in-scope requirement | "also add X" | Amends current plan + states it did; does not spawn a sub-feature for a small change |
| **E8** | M6 | Mid-impl, user adds a large out-of-scope requirement | "also add X" (large) | Creates new sub-feature; finishes current one first; states the choice |
| **E9** | M8 | PR open, CI red on lint only | "CI is failing" | Fixes in place on current sub-feature; no new sub-feature |
| **E10** | M1 | No `.vibekit/config.yaml`; a `.png` written under a sub-feature | `/sdlc <feature>` | `git check-ignore` matches the png; no image blob in any commit; policy resolves to `transient` |
| **E11** | M7 | Feature in `wip/`, user parks it | "park this for now" | Moves dir to `pending/`; records `parked_reason` + `last_completed` |
| **E12** | all | Plan touching frontend + backend, no boundary section | plan review | Review FAILS the plan; names the missing contract |
| **E13** | M2 | State says phase complete, checklist has unchecked items | "continue" | Trusts the checklist over the state file; flags the mismatch |
| **E14** | M3 | Delegate done, checklist 100% `[x]`, `mode: handoff` | "haiku finished" | **Re-runs verify items**; does not trust `[x]`; flips mode only after passing |
| **E15** | M2 | State `worktree:` ≠ cwd | "continue" | STOPS before any write; shows both paths; asks switch-vs-update |
| **E16** | M4 | Reviewer rejected 2× | (continue review) | Presents continue/pause choice; no 4th iteration; no silent proceed |
| **E17** | M1 | `.vibe-station/` in path, no `.vibekit/config.yaml` | `/sdlc <feature>` | All agents in-harness; exactly ONE suggestion line; zero spawn attempts |
| **E18** | M5 | Bug bundle `04-` already open | one more bug, same root cause | Appends to `04-`; does NOT create `05-` |
| **E19** | M5 | Device in use by another session | "verify on the Pixel" | Asks first; offers tests-only; never seizes the device |
| **E20** | — | Transient screenshots + image refs in plan | cleanup step | Refs rewritten to `[screenshot: <name> — removed]`; no broken links |
| **E21** | M6 | PRD says X, plan says not-X | plan review | Flags the conflict; PRD wins; does not silently implement the plan |
| **E22** | M9 | New feature, nothing exists | `/sdlc plan auth-flow` | `plan-auth-flow.md` exists; `git status` shows **no** source file changed; state has `awaiting_phase: plan` + `awaiting_artifact` = that path |
| **E23** | M9 | New feature, nothing exists | `/sdlc prd+plan auth-flow` | Both `prd-` and `plan-` files exist; no source file changed; `awaiting_phase: plan` |
| **E24** | M9 | New feature, nothing exists | `/sdlc prd-plan-implement auth-flow` | All three artifacts present (prd, plan, ≥1 source file changed); **no** test run and no device access; `awaiting_phase: implement` |
| **E25** | M9 | Feature dir literally named `plan/` exists | `/sdlc plan` | `git status` clean at the moment the question is asked; agent asks chain-vs-feature |
| **E26** | M9 | Feature `backup-restore` exists | `/sdlc backup-restore` | Treated as a feature; `phase_chain` is `null` or the full chain — **not** a 2-token chain |
| **E27** | M9 | State `awaiting_phase: plan` | `/sdlc auth-flow` | No source file changed; agent restates the awaited artifact and asks |
| **E28** | M9 | State `awaiting_phase: plan`, `phase_chain: [prd, plan]` | `/sdlc continue` | Runs `implement` **only**; `awaiting_phase` becomes `implement`; does **not** run verify |
| **E29** | — | `.vibekit/config.yaml` with `sdlc.agents.reviewer.gate: user` | `/sdlc plan auth-flow` | No reviewer subagent spawned (`gate: user` spawns nothing); state ends `awaiting_phase: plan` |
| **E30** | — | `.vibekit/config.yaml` with `sdlc.agents.reviewer.gate: both` | `/sdlc plan auth-flow` | Reviewer feedback is surfaced in-conversation **and** state ends `awaiting_phase: plan` (state field is the file-observable half) |
| **E31** | M9 | New feature, nothing exists | `/sdlc implement+plan auth-flow` | `plan-*.md` mtime precedes any changed source file's mtime; the reorder is stated before the first write |
| **E32** | M9 | Feature `auth-flow` exists | `/sdlc add plan` | Creates sub-feature named `plan`; **no** chain parsed; `/sdlc status` shows it in the queue |
| **E33** | M9 | New feature, nothing exists | `/sdlc review auth-flow` | Creates **no** artifact; asks what to review |
| **E34** | — | Sub-feature at `awaiting_phase: review`, review clean | `/sdlc continue` | `awaiting_*` cleared, `mode: done`, feature dir reaches `done/` — the drain is not deadlocked |
| **E35** | — | Sub-feature at `awaiting_phase: plan` | `/sdlc replan <that sub>` | STOPS and asks; does NOT silently supersede the awaited artifact |
| **E36** | — | Nothing awaiting | `/sdlc continue` | Says nothing is awaiting, falls through to normal M2 resume |
| **E37** | — | Fresh session, state has `awaiting_phase` set | `/sdlc <feature>` | Restates the awaited artifact and asks; does NOT auto-advance |
| **E38** | — | Any | `/sdlc impl auth-flow` | Alias normalizes to `implement` in `awaiting_phase`; not treated as a feature name |
| **E39** | — | Large multi-layer feature, no system-level decomposition actually needed | `/sdlc <feature>` | Agent picks `_template_plan.md` (not arch); written doc has `## Implementation Phases`; selector is never invoked by size alone |
| **E40** | — | Feature genuinely needs system-level decomposition upfront | `/sdlc <feature>` | Agent picks `_template_arch.md`; writes `arch-<feature>.md` (not `plan-<feature>.md`); ≥1 `NN-*/plan-NN-*.md` part exists; arch's `## Part Breakdown` rows match the dirs on disk |
| **E41** | M5 | A part (`origin: planned`) hits a bug needing a bundle | verification finds bugs in a part | New entry has `origin: bug-bundle`, `spawned_from: <part id>`; recorded in the **part's** `## Sub-Plan Breakdown`, never in the arch's `## Part Breakdown` |
| **E42** | M1 | New feature, decomposition (with or without an arch) yields zero parts | `/sdlc <feature>` | `.sdlc-state.yaml` has exactly one `subfeatures[]` entry, `id: root`, `origin: planned`; **no** `NN-` directory created; `master.plan: complete` |
| **E43** | M9 | `root` at `awaiting_phase: implement` | `/sdlc continue` | Advances exactly one phase; queue drains to `done/` only after `root.mode: done` — proves the drain gate isn't deadlocked for root-only features |
| **E44** | — | Zero-parts feature run end-to-end, `gate: llm` | `/sdlc <feature>` full run | Reviewer runs over `plan-<feature>.md` **exactly once** — `root` enters the inner cycle at `implement`, not `plan`, so its own plan is never re-reviewed |
| **E45** | M3 | `root` mid-impl, context low | "hand this off to haiku" | Handoff prompt names `plan-<feature>.md`; no `NN` anywhere in the path or prompt |
| **E46** | all | `arch-<feature>.md` drafted with a `## Implementation Phases` section containing `[ ]` items | arch review | Review **FAILS**; names the offending section explicitly; proposes moving the phases into a new part instead |

- E22-E33 cover M9 (scoped invocation) and the `reviewer.gate` config — added with phase composition
- E39-E46 cover the arch/plan restructure — template selection (E39-E40), part-vs-sub-plan provenance (E41), the zero-parts `root` entry (E42-E45), and the arch-must-never-carry-phases invariant (E46)
- The `root` subfeature entry exists from **feature creation (M1)**, not only after decomposition — so E22/E27/E29/E30/E31/E33/E37's "state has `awaiting_phase: plan`" resolves to `root`'s `awaiting_phase`, not a schema gap
- Assertions prefer file-state and negatives over transcript wording, per [`README.md`](./README.md); E24/E31 use `git status` and mtime as the observable proxy for "did not advance" and for ordering

## Running these headless — two constraints learned from the first live run

**1. Approval-gated cases need pre-authorization in the prompt.**
The skill deliberately pauses for human approval at decomposition, bug clustering, runner
config, and screenshot cleanup. Headless has nobody to approve, so the agent correctly does
nothing and the case fails on an assertion describing post-approval state.

- Affected: any case whose pass criteria describe files created *after* an approval gate
- Fix in the prompt, never in the skill — append "consider this pre-approved, do not stop to ask"
- E4 reproduced this exactly: first run created nothing (correct behavior), passed once pre-authorized

**2. "Must not act" cases cannot be verified by filesystem state alone.**
A correct refusal and a broken no-op leave identical file trees. Those cases need a narrow
content assertion on the agent's output — presence of specific factual strings (e.g. both
conflicting paths), never a judgement about wording.

**3. Assert the invariant, not the author's expected answer.**
E4 originally asserted `<=2` sub-features for 4 bugs, based on how *the eval author* would have
grouped them. A live run produced 3 defensible clusters (URI-handling, error-path, atomicity are
genuinely distinct root causes) and the eval failed a correct implementation. The real invariant
is `n < bug_count` — clustering happened. How bugs partition is a judgement call; encoding one
answer makes the eval flaky against equally-valid alternatives.

**4. Every case needs a positive assertion.**
`file unchanged` + `item still [x]` both pass when the agent does nothing. E1 passed vacuously
until a forward-progress assertion was added. Mutation-test each case: seed a do-nothing prompt
and confirm it FAILS.

**Status legend:** `fixtured` = fixture + `assert_<id>` exist in `run.sh`, mutation-tested (do-nothing
fails). `deferred` = not yet built, no known headless blocker — buildable with the techniques already
used here (pre-authorization in the prompt, output-content assertions). `not-fixturable-headless` =
a specific, named reason the technique bag doesn't cover it.

| Case | Headless status |
|------|-----------------|
| E1 | `fixtured` — ✅ run live, passes; mutation-tested |
| E4 | `fixtured` — ✅ run live, passes with pre-authorization; assertion loosened to `n < bug_count` after a false failure |
| E15 | `fixtured` — hybrid, output-content assertion (worktree path must be named in output) |
| E12 | `fixtured` — output-content assertion (review must name "boundary/contract/interface"); mutation-tested |
| E13 | `fixtured` — checklist-wins-over-state + output-content mismatch flag; mutation-tested |
| E14 | `fixtured` — re-verify-don't-trust-`[x]`, `verified_by` must be non-null (not just present); mutation-tested |
| E16 | `fixtured` — escalation choice asserted via output content (`continue` + `pause`); mutation-tested |
| E22 | `fixtured` — M1 "nothing exists yet" fixture (no pre-existing `.vibekit/`); mutation-tested |
| E34 | `fixtured` — the drain-deadlock regression case; asserts the feature dir actually reaches `done/`; mutation-tested |
| E36 | `fixtured` — output-content ("nothing awaiting") + forward-progress assertion; mutation-tested |
| E37 | `fixtured` — hybrid, output must name the awaited artifact; mutation-tested |
| E2 | `deferred` — same prompt-narration technique as E14/E16 applies; not yet built |
| E3 | `deferred` — same technique as E2; not yet built |
| E5 | `deferred` — needs a seeded "approach proven wrong" narrative + `## Superseded` table assertion; not yet built |
| E6 | `deferred` — needs stale file:line refs seeded in a plan against a rebased tree; not yet built |
| E7 | `deferred` — needs a small in-scope scope-change prompt; not yet built |
| E8 | `deferred` — needs a large out-of-scope scope-change prompt; not yet built |
| E9 | `deferred` — needs a simulated CI-red-on-lint-only signal in the prompt; not yet built |
| E10 | `deferred` — needs `git check-ignore` assertion machinery for a `.png` under a sub-feature; not yet built |
| E11 | `deferred` — same pending/ move technique as E7's M7 sibling (M7 already covered narratively in PHASES.md); not yet built |
| E17 | `not-fixturable-headless` — the case setup requires `.vibe-station/` to appear in the **cwd path itself** (harness-path detection); `run.sh`'s `run_case` copies every fixture into a fresh generic `mktemp -d`, which never contains that segment. Testing it needs a `run_case` change to control the workdir path, not just fixture content — out of scope for this pass |
| E18 | `deferred` — needs an already-open `04-` bug-bundle dir seeded, then one more bug reported; not yet built |
| E19 | `deferred` — same prompt-narration technique as E16 ("device already in use, say so"); not yet built |
| E20 | `deferred` — needs seeded screenshot refs + a cleanup-step prompt; not yet built |
| E21 | `deferred` — needs a PRD/plan seeded with a deliberate conflict; not yet built |
| E23 | `deferred` — same M9 chain technique as E22, two-token chain; not yet built |
| E24 | `deferred` — same M9 technique as E22, three-token chain through implement; not yet built |
| E25 | `deferred` — needs a feature dir literally named `plan/` to force the ambiguity branch; not yet built |
| E26 | `deferred` — needs an existing feature whose name collides with nothing (`backup-restore`); not yet built |
| E27 | `deferred` — same awaiting_phase-restate technique as E37, feature-name invocation instead of `continue`; not yet built |
| E28 | `deferred` — same awaiting_phase technique as E37, `/sdlc continue` advancing prd→plan chain; not yet built |
| E29 | `deferred` — needs `gate: user` in `.vibekit/config.yaml`; not yet built |
| E30 | `deferred` — needs `gate: both` in `.vibekit/config.yaml`; not yet built |
| E31 | `deferred` — needs an mtime-ordering assertion for `implement+plan`; not yet built |
| E32 | `deferred` — needs `/sdlc add plan` dispatch-precedence fixture; not yet built |
| E33 | `deferred` — needs a fresh-feature `/sdlc review` fixture asserting "no artifact created"; not yet built |
| E35 | `deferred` — same awaiting-artifact-about-to-be-superseded technique as E37; not yet built |
| E38 | `deferred` — needs an `impl` alias-normalization assertion; not yet built |
| E39 | `deferred` — needs template-selection fixture (`_template_plan.md` vs `_template_arch.md`); not yet built |
| E40 | `deferred` — same as E39, arch branch; needs `## Part Breakdown` assertion; not yet built |
| E41 | `deferred` — needs a part + bug-bundle spawned from it; not yet built |
| E42 | `deferred` — needs a zero-parts decomposition fixture; not yet built |
| E43 | `deferred` — needs a `root`-at-`awaiting_phase: implement` fixture; not yet built |
| E44 | `deferred` — needs a full zero-parts run asserting the reviewer runs exactly once; not yet built |
| E45 | `deferred` — needs a `root` mid-impl handoff fixture with no `NN` anywhere; not yet built |
| E46 | `deferred` — needs an `arch-<feature>.md` seeded with `## Implementation Phases`; not yet built |

---

