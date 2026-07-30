#!/usr/bin/env bash
# Fast structural smoke test for the eval fixtures — no agent spawned, runs in <1s.
#
# A refactor (renaming a directory, moving config) cannot change agent BEHAVIOR; it can
# only break PATHS. This catches that class in a second, where the behavioral suite
# (run.sh) takes minutes per case and is only needed when RULES change.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.." || exit 2
E=skills/sdlc/evals; F=$E/fixtures
FAIL=0
ok(){ echo "ok   $1"; }; bad(){ echo "BAD  $1" >&2; FAIL=1; }

for d in "$F"/*/; do
  id=$(basename "$d")
  [[ -f "$d/prompt.txt" ]] || bad "$id: no prompt.txt"
  grep -q "assert_$id()" "$E/run.sh" || bad "$id: no assert_$id in run.sh"
  # every path the fixture ships must sit under the current layout
  if find "$d" -path '*/.feature-plans/*' -print -quit | grep -q .; then
    bad "$id: fixture still uses the retired .feature-plans/ layout"
  fi
  [[ -d "$d/.vibekit/feature-plans" ]] || bad "$id: no .vibekit/feature-plans tree"
  # a state file must be where the skill will look for it
  find "$d/.vibekit/feature-plans" -name '.sdlc-state.yaml' -print -quit | grep -q . \
    || bad "$id: no .sdlc-state.yaml under .vibekit/feature-plans"
  [[ $FAIL -eq 0 ]] && ok "$id fixture resolves under the current layout"
done

# the installed skill must agree with the repo about where things live
INST="$HOME/.claude/skills/sdlc/SKILL.md"
if [[ -f "$INST" ]]; then
  grep -q "vibekit/feature-plans" "$INST" && ok "installed sdlc skill matches current layout" \
    || bad "installed sdlc skill is STALE — rerun ./install.sh claude-code"
else
  echo "skip installed-skill check (not installed)"
fi

echo; [[ $FAIL -eq 0 ]] && echo "smoke: clean" || echo "smoke: FAILURES"
exit $FAIL
