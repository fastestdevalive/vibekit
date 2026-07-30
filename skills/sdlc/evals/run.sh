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
  local w="$1" plan; plan="$(find "$w/.feature-plans" -name 'plan-*.md' | head -1)"
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
  n="$(find "$w/.feature-plans" -maxdepth 3 -type d -name '0[2-9]-*' | wc -l)"
  [[ "$n" -ge 1 ]] || { echo "  no bug-bundle sub-feature created" >&2; return 1; }
  [[ "$n" -lt "$BUG_COUNT" ]] || { echo "  created $n sub-features for $BUG_COUNT bugs — no clustering" >&2; return 1; }
  grep -rq "origin: bug-bundle" "$w/.feature-plans" || { echo "  origin: bug-bundle not set" >&2; return 1; }
  grep -rq "spawned_from" "$w/.feature-plans" || { echo "  spawned_from not set" >&2; return 1; }
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
