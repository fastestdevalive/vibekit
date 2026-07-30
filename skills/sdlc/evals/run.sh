#!/usr/bin/env bash
# Tier B behavioral eval runner.
#
# Drives the installed sdlc/report skills with `claude -p` against a throwaway fixture
# repo and asserts on FILESYSTEM STATE — never on wording. Prose assertions are not
# reproducible across runs; file state is.
#
# Usage:
#   ./run.sh              # run every case that has a fixture dir
#   ./run.sh E1 E4        # run named cases
#   DRY=1 ./run.sh E1     # print the prompt + assertions, spawn nothing
#
# Exit 0 only if every selected case passes.

set -uo pipefail

EVALS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES="$EVALS_DIR/fixtures"
PASS=0; FAIL=0; SKIP=0
RESULTS=()

pass() { PASS=$((PASS+1)); RESULTS+=("PASS  $1"); echo "PASS  $1"; }
fail() { FAIL=$((FAIL+1)); RESULTS+=("FAIL  $1 — $2"); echo "FAIL  $1 — $2" >&2; }
skip() { SKIP=$((SKIP+1)); RESULTS+=("SKIP  $1 — $2"); echo "SKIP  $1 — $2"; }

need_claude() {
  command -v claude >/dev/null 2>&1 || { echo "claude CLI not on PATH" >&2; exit 2; }
}

# run_case <id> <fixture-dir> <prompt-file> <assert-fn>
run_case() {
  local id="$1" fixture="$2" promptfile="$3" assert_fn="$4"

  if [[ ! -d "$fixture" ]]; then skip "$id" "no fixture at $fixture"; return; fi
  if [[ ! -f "$promptfile" ]]; then skip "$id" "no prompt file"; return; fi

  local work; work="$(mktemp -d)"
  cp -R "$fixture/." "$work/"
  ( cd "$work" && git init -q && git add -A && git -c user.email=e@e -c user.name=e commit -qm init )

  if [[ "${DRY:-0}" == "1" ]]; then
    echo "--- $id prompt ---"; cat "$promptfile"; echo "--- fixture: $work"; return
  fi

  # --permission-mode so the agent can actually write; scoped to the throwaway workdir
  ( cd "$work" && timeout 600 claude -p "$(cat "$promptfile")" \
      --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
      --permission-mode acceptEdits >"$work/.agent-output.txt" 2>&1 )

  if "$assert_fn" "$work"; then pass "$id"; else fail "$id" "assertions failed (workdir kept: $work)"; return; fi
  rm -rf "$work"
}

# ---------------------------------------------------------------- assertions

# E1 — resume must start at the first unchecked item and not redo completed work
assert_E1() {
  local w="$1" plan; plan="$(find "$w/.vibekit/feature-plans" -name 'plan-*.md' | head -1)"
  [[ -f "$plan" ]] || { echo "  no plan file" >&2; return 1; }
  # items 1.1-1.3 must remain [x]; nothing that was [x] may have been unchecked
  grep -qE '^\- \[x\] \*\*1\.1\*\*' "$plan" || { echo "  1.1 no longer [x]" >&2; return 1; }
  grep -qE '^\- \[x\] \*\*1\.3\*\*' "$plan" || { echo "  1.3 no longer [x]" >&2; return 1; }
  # the file owned by the already-done items must be byte-identical to the fixture
  if ! git -C "$w" diff --quiet -- src/done_already.txt; then
    echo "  agent edited a file covered by completed items" >&2; return 1
  fi
  # POSITIVE assertion — without this the case passes vacuously when the agent does nothing
  if [[ ! -f "$w/src/next_step.txt" ]] && ! grep -qE '^\- \[x\] \*\*1\.4\*\*' "$plan"; then
    echo "  no forward progress: 1.4 neither done nor marked" >&2; return 1
  fi
  return 0
}

# E4 — 4 bugs must NOT become 4 plans. The invariant is "clustering happened", not a
# specific grouping: how bugs partition by root cause is a judgement call the eval must not
# encode. An earlier <=2 assertion failed a run that produced 3 defensible clusters.
BUG_COUNT=4
assert_E4() {
  local w="$1" n
  n="$(find "$w/.vibekit/feature-plans" -maxdepth 3 -type d -name '0[2-9]-*' | wc -l)"
  [[ "$n" -ge 1 ]] || { echo "  no bug-bundle sub-feature created" >&2; return 1; }
  [[ "$n" -lt "$BUG_COUNT" ]] || { echo "  created $n sub-features for $BUG_COUNT bugs — no clustering" >&2; return 1; }
  grep -rq "origin: bug-bundle" "$w/.vibekit/feature-plans" || { echo "  origin: bug-bundle not set" >&2; return 1; }
  grep -rq "spawned_from" "$w/.vibekit/feature-plans" || { echo "  spawned_from not set" >&2; return 1; }
  return 0
}

# E15 — worktree mismatch must stop before any write
# HYBRID: a correct refusal and a broken no-op leave identical file trees, so this case
# also asserts on output CONTENT — presence of both conflicting paths, never wording quality.
assert_E15() {
  local w="$1" out="$1/.agent-output.txt"
  # negative: nothing may be written
  if ! git -C "$w" diff --quiet; then
    echo "  agent wrote tracked files despite a worktree mismatch" >&2; return 1
  fi
  if git -C "$w" status --porcelain | grep -v '.agent-output.txt' | grep -q .; then
    echo "  agent created files despite a worktree mismatch" >&2; return 1
  fi
  # positive: it must actually have noticed, not merely done nothing
  grep -q "/nonexistent/other-worktree" "$out" || {
    echo "  never surfaced the recorded worktree path — indistinguishable from a no-op" >&2; return 1; }
  return 0
}

# E34 — /sdlc continue at awaiting_phase: review, review clean → clears the pause,
# mode: done, and the queue actually DRAINS to done/. This is the fix for the drain
# deadlock: without the release rule, done/ is unreachable.
assert_E34() {
  local w="$1"
  local donedir="$w/.vibekit/feature-plans/done/demo"
  [[ -d "$donedir" ]] || { echo "  feature not moved to done/ — queue drain did not complete" >&2; return 1; }
  local state; state="$(find "$donedir" -name '.sdlc-state.yaml' 2>/dev/null | head -1)"
  [[ -f "$state" ]] || { echo "  no state file under done/" >&2; return 1; }
  grep -q "mode: done" "$state" || { echo "  subfeature mode not set to done" >&2; return 1; }
  if grep -qE "awaiting_phase:\s*review" "$state"; then
    echo "  awaiting_phase still review — pause not cleared" >&2; return 1
  fi
  if [[ -d "$w/.vibekit/feature-plans/wip/demo" ]]; then
    echo "  stale copy left behind in wip/" >&2; return 1
  fi
  return 0
}

# E14 — a delegate (haiku) reports done with checklist 100% [x], but the artifact it
# claims to have produced is actually wrong. The parent must re-run verify itself, not
# trust the [x] marks, and the mismatch must surface somewhere observable.
assert_E14() {
  local w="$1" state
  state="$(find "$w/.vibekit/feature-plans" -name '.sdlc-state.yaml' 2>/dev/null | head -1)"
  [[ -f "$state" ]] || { echo "  no state file" >&2; return 1; }
  # verified_by set to a NON-null value — the fixture seeds the key present-but-null
  # (matching the canonical schema), so mere key presence must not count as a pass
  local verified_by_set=1
  grep -qE 'verified_by:[[:space:]]*[^[:space:]]+' "$state" \
    && ! grep -qE 'verified_by:[[:space:]]*(null|~)?[[:space:]]*$' "$state" \
    && verified_by_set=0
  # negative: must not blindly trust [x] and flip straight to done without re-verifying
  if grep -q "mode: done" "$state" && [[ "$verified_by_set" -ne 0 ]]; then
    echo "  flipped to done without recording a re-verification" >&2; return 1
  fi
  # positive: it actually looked — recorded verified_by, flagged the bad file in
  # output, or spawned a bug-bundle sub-feature for the broken result
  if [[ "$verified_by_set" -eq 0 ]]; then return 0; fi
  if grep -qi "result.txt" "$w/.agent-output.txt" 2>/dev/null; then return 0; fi
  if find "$w/.vibekit/feature-plans" -maxdepth 3 -type d -name '0[2-9]-*' 2>/dev/null | grep -q .; then return 0; fi
  echo "  no evidence the checklist [x] marks were independently re-verified" >&2
  return 1
}

# E16 — reviewer already rejected twice (max_iterations: 2, reached). Must escalate —
# present continue-vs-pause — never run a silent 3rd iteration.
assert_E16() {
  local w="$1"
  local out="$w/.agent-output.txt"
  local plan; plan="$(find "$w/.vibekit/feature-plans" -name 'plan-*.md' 2>/dev/null | head -1)"
  [[ -f "$plan" ]] || { echo "  no plan file" >&2; return 1; }
  if grep -qi "Iteration 3" "$plan"; then
    echo "  ran a 3rd review iteration past max_iterations" >&2; return 1
  fi
  grep -q "Iteration 1: REJECTED" "$plan" || { echo "  review history was rewritten" >&2; return 1; }
  grep -q "Iteration 2: REJECTED" "$plan" || { echo "  review history was rewritten" >&2; return 1; }
  # positive: the escalation choice was actually presented, not silently skipped
  if grep -qi "continue" "$out" 2>/dev/null && grep -qi "pause" "$out" 2>/dev/null; then
    return 0
  fi
  echo "  escalation choice (continue vs pause) not surfaced in output" >&2
  return 1
}

# E36 — /sdlc continue with nothing awaiting must say so, then fall through to normal
# M2 resume (forward progress) rather than erroring or silently doing nothing.
assert_E36() {
  local w="$1"
  local out="$w/.agent-output.txt"
  local plan; plan="$(find "$w/.vibekit/feature-plans" -name 'plan-*.md' 2>/dev/null | head -1)"
  [[ -f "$plan" ]] || { echo "  no plan file" >&2; return 1; }
  # Assert the INVARIANT, not the phrasing. An earlier version required the words
  # "nothing is awaiting"; the skill correctly resumed and reported progress instead,
  # so a correct implementation failed. Same trap as E4's "<=2 clusters".
  # positive — it fell through to normal resume and advanced
  if [[ ! -f "$w/src/next_step.txt" ]] && ! grep -qE '^\- \[x\] \*\*1\.2\*\*' "$plan"; then
    echo "  no forward progress: did not fall through to normal resume" >&2; return 1
  fi
  # negative — `continue` must dispatch as a SUBCOMMAND, never be parsed as a feature name
  if find "$w/.vibekit/feature-plans" -maxdepth 3 -type d -name 'continue*' 2>/dev/null | grep -q .; then
    echo "  parsed 'continue' as a feature name instead of dispatching it" >&2; return 1
  fi
  # negative — must not invent a pause where none existed
  local state; state="$(find "$w/.vibekit/feature-plans" -name '.sdlc-state.yaml' 2>/dev/null | head -1)"
  if [[ -f "$state" ]] && grep -qE 'awaiting_phase:[[:space:]]*[^[:space:]n~]' "$state"; then
    echo "  set awaiting_* despite nothing having been awaited" >&2; return 1
  fi
  return 0
}

# E37 — fresh session, awaiting_phase set → restate + ask, never auto-advance into
# implement. Hybrid: a correct pause and a broken no-op leave similar trees, so this
# also asserts output CONTENT (the awaited artifact must be named).
assert_E37() {
  local w="$1"
  local out="$w/.agent-output.txt"
  if [[ -f "$w/src/a.txt" || -f "$w/src/b.txt" ]]; then
    echo "  auto-advanced into implement despite an outstanding awaiting_phase" >&2; return 1
  fi
  local plan; plan="$(find "$w/.vibekit/feature-plans" -name 'plan-*.md' 2>/dev/null | head -1)"
  [[ -f "$plan" ]] || { echo "  no plan file" >&2; return 1; }
  if grep -qE '^\- \[x\]' "$plan"; then
    echo "  checklist items got checked despite an outstanding awaiting_phase" >&2; return 1
  fi
  local state; state="$(find "$w/.vibekit/feature-plans" -name '.sdlc-state.yaml' 2>/dev/null | head -1)"
  [[ -f "$state" ]] || { echo "  no state file" >&2; return 1; }
  grep -q "awaiting_phase: plan" "$state" || { echo "  awaiting_phase was cleared without /sdlc continue" >&2; return 1; }
  grep -q "plan-01-demo-core.md" "$out" 2>/dev/null || {
    echo "  never restated the awaited artifact — indistinguishable from a no-op" >&2; return 1; }
  return 0
}

# E13 — state claims the sub-feature is done (last_completed: 1.3), but the checklist
# still has 1.3 unchecked. The checklist must win: forward progress on 1.3, AND the
# mismatch must be flagged, not silently smoothed over.
assert_E13() {
  local w="$1"
  local out="$w/.agent-output.txt"
  local plan; plan="$(find "$w/.vibekit/feature-plans" -name 'plan-*.md' 2>/dev/null | head -1)"
  [[ -f "$plan" ]] || { echo "  no plan file" >&2; return 1; }
  if [[ ! -f "$w/src/c.txt" ]] && ! grep -qE '^\- \[x\] \*\*1\.3\*\*' "$plan"; then
    echo "  trusted the state file's 'done' claim over the checklist — no forward progress" >&2; return 1
  fi
  if ! grep -qiE "mismatch|inconsisten|conflict|disagree|out of sync|out-of-sync" "$out" 2>/dev/null; then
    echo "  did not flag the state/checklist mismatch" >&2; return 1
  fi
  return 0
}

# E12 — a plan spanning frontend + backend with no boundary/interface contract section
# must FAIL review, naming the missing contract specifically.
assert_E12() {
  local w="$1"
  local out="$w/.agent-output.txt"
  [[ -s "$out" ]] || { echo "  no agent output produced" >&2; return 1; }
  if ! grep -qiE "fail|reject|not ready|not pass|missing" "$out" 2>/dev/null; then
    echo "  review did not report a failure" >&2; return 1
  fi
  if ! grep -qiE "boundary|contract|interface" "$out" 2>/dev/null; then
    echo "  review failed but never named the missing boundary contract" >&2; return 1
  fi
  if [[ -f "$w/src/api/serializer.py" || -f "$w/src/ui/ExportScreen.kt" ]]; then
    echo "  agent implemented instead of reviewing" >&2; return 1
  fi
  return 0
}

# E22 — /sdlc plan <feature> on a brand-new feature is a 1-token chain: writes the plan,
# reviews it, and STOPS at the chain end — implement never runs even though the
# reviewer gate is the auto-advancing default (llm).
assert_E22() {
  local w="$1"
  local planfile; planfile="$(find "$w/.vibekit/feature-plans" -maxdepth 4 -name 'plan-auth-flow.md' 2>/dev/null | head -1)"
  [[ -f "$planfile" ]] || { echo "  plan-auth-flow.md not created" >&2; return 1; }
  if git -C "$w" status --porcelain 2>/dev/null | grep -v '^?? \.vibekit/' | grep -v '\.agent-output\.txt' | grep -q .; then
    echo "  files outside .vibekit/ were touched — implement ran past the chain end" >&2; return 1
  fi
  local state; state="$(find "$w/.vibekit/feature-plans" -name '.sdlc-state.yaml' 2>/dev/null | head -1)"
  [[ -f "$state" ]] || { echo "  no state file created" >&2; return 1; }
  grep -q "awaiting_phase: plan" "$state" || { echo "  awaiting_phase not set to plan at chain end" >&2; return 1; }
  grep -q "plan-auth-flow.md" "$state" || { echo "  awaiting_artifact does not point at the plan" >&2; return 1; }
  return 0
}

# ---------------------------------------------------------------- dispatch

CASES=("$@")
if [[ ${#CASES[@]} -eq 0 ]]; then
  CASES=()
  for d in "$FIXTURES"/*/; do [[ -d "$d" ]] && CASES+=("$(basename "$d")"); done
fi
DECLARED=$(grep -c "^| \*\*E" "$EVALS_DIR/cases.md" 2>/dev/null || echo "?")

[[ "${DRY:-0}" == "1" ]] || need_claude

for id in "${CASES[@]}"; do
  run_case "$id" "$FIXTURES/$id" "$FIXTURES/$id/prompt.txt" "assert_$id"
done

echo
echo "passed=$PASS failed=$FAIL skipped=$SKIP  (of $DECLARED declared cases — fixtures exist for ${#CASES[@]})"
[[ "$FAIL" -eq 0 ]]
