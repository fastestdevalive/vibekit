# Report: What would a `turn-implement` mode change in the `sdlc` skill?

**Date:** 2026-09-16 · **Commit:** `d62b5d5` · **Scope:** `skills/sdlc/{SKILL,PHASES,GRAMMAR}.md`, `vibekit.example.yaml`, `sdlc-state.example.yaml`, `skills/planning/_template_plan.md` · **Method:** design read of current implement/reviewer-gate machinery, no code written

## Answer
- Today's `implementer` runs **one long-lived session for the whole plan checklist** (`PHASES.md` Spawn rules, `SKILL.md` Runner table). `turn-implement` instead spawns **one implementer per plan `Implementation Phase`**, verifies that phase's `N.T*` block, then kills it and spawns a fresh one for the next phase — good for a fast-but-not-durable local model that chokes on a big context but flies on a small, self-contained one.
- The plan template already has the right granularity for free: `Phase 1 / Phase 2 / Phase 3`, each ending in a **verify block** (`skills/planning/_template_plan.md:225-265`). No new planning-skill work needed — turn-implement rides the existing checklist shape.
- The real work is a **new gate dimension** parallel to `sdlc.agents.reviewer.gate`, but keyed on test results per phase instead of an LLM review of a document — plus a state-schema decision for tracking *which* phase is mid-flight (today's `awaiting_phase` is phase-token-grained, not sub-phase-grained).
- Biggest gotcha: **each turn is a fresh agent with zero memory of the last one.** Anything decided ad hoc during Phase 1 that isn't written back into the plan file is invisible to Phase 2's agent. The plan file becomes the *only* channel between turns — this needs to be a hard rule, not a hope.

## Evidence
| Claim | Source |
|-------|--------|
| Implementer is currently one session for the whole checklist, in-harness by default | `skills/sdlc/SKILL.md:282-314` (Runner table + fallback chain) |
| Reviewer gate pattern (`llm/user/both`) is the closest existing analog for a new turn-level gate | `skills/sdlc/SKILL.md:81-89`, `skills/sdlc/GRAMMAR.md:75-89` |
| Plans already decompose into `Phase 1/2/3`, each with its own `N.Tn` verify block | `skills/planning/_template_plan.md:223-267` |
| Progress lives in the checklist, not per-phase state fields — checklist wins on conflict | `skills/sdlc/SKILL.md:253`, `skills/sdlc/PHASES.md:45-47` |
| `awaiting_phase` is one of `prd\|plan\|implement\|verify\|review` — a single coarse token, not phase-numbered | `skills/sdlc/SKILL.md:266`, `skills/sdlc/GRAMMAR.md:36-42` |
| Handoff return path already distrusts self-reported `[x]` marks and re-runs verify | `skills/sdlc/PHASES.md:132-140` |
| `implementer.run_in` today defaults to `in-harness`; meta-harness is spec'd but the doc doesn't yet describe *why* you'd want it beyond "long-running, survives session death" | `vibekit.example.yaml:76-83` |
| Ask-before-device is unconditional per verification pass, not scoped to a sub-step | `skills/sdlc/PHASES.md:53-54` |
| One commit per sub-feature is the standing rule; only `.vibekit/feature-plans/**` may auto-commit | `skills/sdlc/PHASES.md:71-84` |

## Detail

### Config additions (`vibekit.example.yaml` + `SKILL.md` config schema)
```yaml
sdlc:
  agents:
    implementer:
      mode: session        # [new] session (default, current behavior) | turn
      turn_gate: auto       # [new, only read when mode: turn] auto | user | review
      max_turn_retries: 2   # [new] mirrors reviewer.max_iterations, per-phase not per-doc
```
- `mode: session` is the default — **zero behavior change** for anyone not opting in.
- `turn_gate` is a **separate knob from `reviewer.gate`** — don't let it collide in naming or in the mental model. `reviewer.gate` governs document review (PRD/plan/review token). `turn_gate` governs implementation-phase advancement and is judged by tests, not an LLM reading a diff.

| `turn_gate` | After phase verify passes | After phase verify fails |
|---|---|---|
| `auto` (default) | auto-advance to next phase, no stop | respawn implementer with failure output, up to `max_turn_retries`, then escalate (same 2-option escalation as reviewer exhaustion) |
| `user` | stop, report `[x]` phase + await `/sdlc continue` | escalate immediately, no silent retry |
| `review` | spawn reviewer subagent on the phase's diff before advancing (expensive — mirrors `both`) | same as `auto`'s retry path, then escalate |

### PHASES.md — new "Turn-implement" subsection (sibling to "Reviewer invocation")
Per phase `N`:
1. Build a **scoped prompt**: only Phase N's checklist items (`N.1..N.k`) + its `Files & Phase Impact` rows + pointer to `coding-agent-guardrails`/`coding` skills — **not the whole plan**. This is what makes it viable for a fast/small-context local model; it's the same self-containment bar already used for Handoff (M3), just re-used per phase instead of per whole-plan delegation.
2. Spawn implementer (meta-harness when configured, in-harness fallback — same runner fallback chain as today).
3. Implementer marks `N.1..N.k` `[x]` and reports done. **Terminate the session immediately** — do not keep it alive to also run verify.
4. Orchestrator (not the terminated implementer) runs Phase N's `N.T*` verify block for real — reuse the existing Verifier role (in-harness, needs parent's device context) so device/UI checks still work.
5. Gate per `turn_gate` table above.
6. Before terminating, implementer must write back **any decision or deviation** to the plan (a `## Turn Notes` scratch block, or the plan's existing `Key Decisions` section) — this is the only way Phase N+1's fresh agent learns it. Make this a required step in the canonical per-turn prompt, not an aspiration.

### State schema — `.sdlc-state.yaml`
Two options, pick one deliberately (this report doesn't decide it for you):

| Option | Mechanism | Trade-off |
|---|---|---|
| A — derive from `last_completed` | Parse the leading integer off `last_completed` (e.g. `"2.T2"` → phase 2) and cross-reference the plan's phase count | No schema churn, but `/sdlc status` needs to re-parse the plan file every time, and it's fragile if a plan's phases are renumbered non-sequentially |
| B — explicit field | Add `subfeatures[].impl_turn: {phase: 2, of: 3, retries: 1}` | Cheap to read, survives renumbering, but is new schema surface that `sdlc-state.example.yaml` and every consumer (`/sdlc status`, `/sdlc list`) must learn |

- Recommend **B** — it's a small, additive field and avoids coupling `sdlc`'s resume logic to `planning`'s checklist-numbering convention.
- `awaiting_phase` stays `implement` (unchanged token set) — `impl_turn` is the sub-resolution inside it, same relationship `last_completed` already has to `awaiting_artifact`.

### Chain-token interaction (`GRAMMAR.md`)
- `/sdlc implement <feature>` today means "run the whole implement phase, then chain-end stop." Under `turn_gate: auto` this is unchanged: all phases run back-to-back inside one invocation, tests gate each hop, chain-end stop still applies after the last phase.
- Under `turn_gate: user`, `/sdlc implement <feature>` effectively behaves like an *implicit* one-phase-at-a-time chain even though the user typed the coarse `implement` token — each phase boundary now also produces an `awaiting_phase: implement` stop (with `impl_turn` telling you which phase). This needs one explicit line in `GRAMMAR.md` so it isn't a silent surprise: **`turn_gate: user` turns every phase boundary into a gate stop, independent of what chain was typed.**

## Not checked
- Did not look at how the `planning` skill's `scaffold.sh` or evals (`skills/sdlc/evals/*`) would need a new fixture for `mode: turn` — a working implementation would need at least one new eval case (`E##`) exercising phase-boundary termination + resume, mirroring the existing `.sdlc-state.yaml` fixtures under `skills/sdlc/evals/fixtures/`.
- Did not evaluate actual meta-harness spawn/teardown latency (session bootstrap, tool re-discovery cost per turn) — for plans with many small phases this overhead could dominate wall-clock against a fast local model; worth a real timing check before committing to per-phase (vs. per-2-phases) granularity.
- Did not check whether `planning`'s current phase-sizing guidance (`_template_plan.md`) already produces phases sized well for turn-implement, or whether it needs a nudge toward not over-splitting — that's a `planning`-skill concern this report didn't open.

## Follow-ups
| # | Question | Why it matters |
|---|----------|-----------------|
| 1 | Explicit state field (`impl_turn`) vs. derive-from-`last_completed` — which one? | Determines schema churn and how much `/sdlc status`/`/sdlc list` code changes |
| 2 | Does source get auto-committed per verified phase, or does "always ask" still apply per phase? | Crash-resilience (a dead local-model turn shouldn't lose prior phases' work) vs. commit-noise |
| 3 | Should `turn_gate: review` exist at all, or is `auto`/`user` sufficient for v1? | `review` doubles reviewer-subagent cost per phase instead of per document — may not be worth it |
| 4 | Per-phase model override (e.g. fast model for Phase 1, smarter model for a judgment-heavy Phase 3)? | Not needed for the deepseek use case as stated, but a natural extension once `mode: turn` exists |
| 5 | One `/sdlc plan` command or a phase-sizing hint so plans written for turn-implement don't over-split into too many tiny phases? | Turn overhead is per-phase; a 10-phase plan means 10 spawns regardless of gate setting |
