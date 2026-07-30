# SDLC skill evals

> Excluded from adapter installs — `adapters/claude-code/install.sh` skips `evals/` on copy.

- Each eval = setup state + prompt + pass/fail assertions on agent behavior
- Purpose: catch regressions in skill wording that change agent behavior
- V1: no fixture directories, no automated runner for behavioral cases — each case states its setup in table form; the operator sets it up by hand and runs the prompt

## Tiers

| Tier | What | When | Needs an LLM? |
|------|------|------|:---:|
| **A — deterministic lint** | File-state / doc-content checks (`evals/lint.sh`, `evals/prose-lint.py`) | Every PR | No |
| **B — behavioral** | Cases in [`cases.md`](./cases.md) (E1-E46) | Nightly + `run-evals` label | Yes |

## Running Tier A locally

```bash
bash skills/sdlc/evals/lint.sh
python3 skills/sdlc/evals/prose-lint.py
```

## Running a Tier B case manually

1. Open the case row in `cases.md` — read **Setup state**
2. Create that state by hand under a scratch `.vibekit/feature-plans/` tree
3. Run the **Prompt** against a fresh agent session with the `sdlc` skill installed
4. Check the transcript + resulting files against **Pass criteria**

## Assertion types

| Type | Example |
|------|---------|
| **File-state** | New dir `03-*/` exists with exactly one `plan-03-*.md` |
| **Doc-content** | `## Superseded` present; boundary table has typed fields |
| **Negative** | No file added under `screenshots/`; no `[x]` item re-edited |
| **Response-content** | Answer names the specific gap, not a generic "looks good" |

- **Assert on file-system side effects, not on wording** where possible — the only way these stay stable
- Keep Tier B off the PR path; retry known-flaky cases 2-of-3
