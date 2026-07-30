#!/usr/bin/env bash
# Tier A deterministic lint — no LLM, no secrets. Run on every PR.
#
# Usage: bash skills/sdlc/evals/lint.sh   (from repo root, or anywhere — path-independent)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
SCHEMA_CHECK="$(dirname "${BASH_SOURCE[0]}")/schema-check.py"
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "pass: $1"; }

# 1. AGENTS.md convention retired
if find skills -name AGENTS.md | grep -q .; then
  fail "skills/**/AGENTS.md still present — convention retired"
else
  pass "no skills/**/AGENTS.md"
fi

# 2. Companions must be linked from SKILL.md
if grep -L "FORMAT.md" skills/planning/SKILL.md skills/prd/SKILL.md | grep -q .; then
  fail "FORMAT.md not linked from every SKILL.md that should reference it"
else
  pass "FORMAT.md linked from planning + prd SKILL.md"
fi

# 3. Line cap by load class — always-loaded (400) vs on-demand companions (600).
#    Templates (`_template_*.md`, `_*_sample_*.md`) are exempt — copied, never loaded as context.
#    This file is tooling, not skill content, so it may name any skill directly.
ALWAYS_LOADED="CLAUDE.md AGENTS.md GEMINI.md $(find skills -maxdepth 2 -iname 'SKILL.md' | sort)"
for f in $ALWAYS_LOADED; do
  [[ -f "$f" ]] || continue
  n=$(wc -l < "$f")
  if [[ "$n" -ge 400 ]]; then
    fail "$f is $n lines — must be < 400 (always-loaded)"
  else
    pass "$f is $n lines (< 400, always-loaded)"
  fi
done

COMPANIONS="skills/planning/FORMAT.md skills/planning/SECTIONS.md skills/prd/FORMAT.md \
skills/sdlc/PHASES.md skills/sdlc/GRAMMAR.md skills/sdlc/EXAMPLES.md"
for f in $COMPANIONS; do
  [[ -f "$f" ]] || continue
  n=$(wc -l < "$f")
  if [[ "$n" -ge 600 ]]; then
    fail "$f is $n lines — must be < 600 (on-demand companion)"
  else
    pass "$f is $n lines (< 600, on-demand companion)"
  fi
done

# 4. Diagrams exist
n=$(grep -c mermaid skills/planning/*.md | awk -F: '{s+=$2} END {print s+0}')
if [[ "$n" -eq 0 ]]; then
  fail "no mermaid diagrams found under skills/planning/"
else
  pass "$n mermaid occurrences under skills/planning/"
fi

# 5. Stale template ref
if grep -rn "_plan_sample_format.md" . --include="*" 2>/dev/null | grep -v "^./.vibekit/feature-plans/" | grep -v "^./.git/" | grep -v "^./skills/sdlc/evals/lint.sh" | grep -q .; then
  fail "stale _plan_sample_format.md reference found"
else
  pass "no stale _plan_sample_format.md references"
fi

# 5b. Stale big/small plan template ref — the arch/plan restructure retired these names.
if grep -rn "_plan_sample_big\|_plan_sample_small" . --include="*" 2>/dev/null | grep -v "^./.vibekit/feature-plans/" | grep -v "^./.git/" | grep -v "^./skills/sdlc/evals/lint.sh" | grep -q .; then
  fail "stale _plan_sample_big/_plan_sample_small reference found"
else
  pass "no stale _plan_sample_big/_plan_sample_small references"
fi

# 5c. Stale .feature-plans/ or .reports/ path reference — the dir-consolidation move retired
#     these top-level names in favor of .vibekit/feature-plans/ and .vibekit/reports/.
#     Everything under .vibekit/feature-plans/ (done/ archive, plus pending/wip plans that
#     narrate the rename itself) is exempt, matching checks 5/5b's precedent in this file.
#     Every other surface — skill docs, scripts, root docs — must use the new paths.
if grep -rn "\.feature-plans\|\.reports/" . --include="*" 2>/dev/null \
    | grep -v "^./.vibekit/feature-plans/" \
    | grep -v "^./.git/" \
    | grep -v "^./skills/sdlc/evals/lint.sh" \
    | grep -q .; then
  fail "stale .feature-plans/ or .reports/ reference found outside .vibekit/feature-plans/"
else
  pass "no stale .feature-plans/ or .reports/ references outside the archive"
fi

# 6. Lowercase stale ref
if grep -n "skill\.md" README.md AGENTS.md 2>/dev/null | grep -q .; then
  fail "lowercase skill.md reference found in README.md/AGENTS.md"
else
  pass "no lowercase skill.md references"
fi

# 7. scaffold.sh must exit 0
TMPD="$(mktemp -d)"
if bash skills/planning/scaffold.sh "$TMPD" >/dev/null; then
  pass "scaffold.sh exits 0"
else
  fail "scaffold.sh did not exit 0"
fi
rm -rf "$TMPD"

# 8. EVERY adapter must skip a companion-only dir, not abort mid-loop.
#    Was cursor-only; agy shipped uncovered and claude-code was missing the guard entirely.
mkdir -p skills/_probe && echo probe > skills/_probe/NOTES.md
for adp in claude-code cursor gemini agy; do
  TMPD2="$(mktemp -d)"
  if [[ "$adp" == "claude-code" ]]; then
    CLAUDE_SKILLS_DIR="$TMPD2" ./install.sh "$adp" >/dev/null 2>&1
  else
    ./install.sh "$adp" all "$TMPD2" >/dev/null 2>&1
  fi
  rc=$?
  n=$(find "$TMPD2" \( -name 'SKILL.md' -o -name '*.mdc' -o -name '*.md' \) 2>/dev/null | wc -l)
  # A companion-only dir must be SKIPPED: neither aborting the run nor installing
  # as a bogus skill. claude-code silently did the latter — install_one only
  # tested that the source dir exists, never that it holds a SKILL.md.
  bogus=$(find "$TMPD2" -path '*_probe*' 2>/dev/null | wc -l)
  if [[ $rc -eq 0 && $n -ge 5 && $bogus -eq 0 ]]; then
    pass "$adp skips a SKILL.md-less dir and still installs every skill"
  else
    fail "$adp mishandled a companion-only dir (rc=$rc files=$n bogus=$bogus)"
  fi
  rm -rf "$TMPD2"
done
rm -rf skills/_probe

# 9. claude-code install excludes evals/ and CONTRIBUTING.md
TMPD3="$(mktemp -d)"
CLAUDE_SKILLS_DIR="$TMPD3" ./adapters/claude-code/install.sh >/dev/null
if [[ -e "$TMPD3/sdlc/evals" ]]; then
  fail "sdlc/evals/ was installed — must be excluded"
else
  pass "sdlc/evals/ excluded from install"
fi
if find "$TMPD3" -iname "CONTRIBUTING.md" | grep -q .; then
  fail "a CONTRIBUTING.md was installed — must be excluded"
else
  pass "CONTRIBUTING.md excluded from install"
fi
rm -rf "$TMPD3"

# --- phase composition (M9) — each check must FAIL on a tree without the feature ---

# 10. SKILL.md and GRAMMAR.md must declare the SAME phase-token set.
#     Structural (table rows), not bare word presence — all five words already occur
#     in both files for unrelated reasons, so a word-presence check would be vacuous.
tok() { grep -oE '^\| `(prd|plan|implement|verify|review)`' "$1" 2>/dev/null | tr -d '|` ' | sort -u; }
if [[ ! -f skills/sdlc/GRAMMAR.md ]]; then
  fail "skills/sdlc/GRAMMAR.md missing — phase-token grammar has no home"
elif [[ -z "$(tok skills/sdlc/GRAMMAR.md)" ]]; then
  fail "GRAMMAR.md has no phase-token table rows"
elif ! diff <(tok skills/sdlc/SKILL.md) <(tok skills/sdlc/GRAMMAR.md) >/dev/null; then
  fail "phase-token tables differ between SKILL.md and GRAMMAR.md"
else
  pass "phase-token tables agree ($(tok skills/sdlc/GRAMMAR.md | tr '\n' ' '))"
fi

# 11. The pause is an orthogonal field, never a mode value.
MISSING_AWAIT=""
for f in skills/sdlc/SKILL.md skills/sdlc/PHASES.md skills/sdlc/GRAMMAR.md; do
  grep -q "awaiting_phase" "$f" 2>/dev/null || MISSING_AWAIT="$MISSING_AWAIT $f"
done
if [[ -n "$MISSING_AWAIT" ]]; then
  fail "awaiting_phase absent from:$MISSING_AWAIT"
else
  pass "awaiting_phase documented in SKILL.md, PHASES.md, GRAMMAR.md"
fi
if grep -l "awaiting_user" skills/sdlc/*.md 2>/dev/null | grep -q .; then
  fail "awaiting_user found — the pause must not be a mode enum value"
else
  pass "no awaiting_user mode value"
fi

# 12. reviewer.gate present in the config template, and the template still parses.
if python3 -c "
import yaml,sys
d=yaml.safe_load(open('vibekit.example.yaml'))
sys.exit(0 if 'gate' in (d.get('sdlc',{}).get('agents',{}).get('reviewer') or {}) else 1)" 2>/dev/null; then
  pass "sdlc.agents.reviewer.gate present at the correct path"
else
  fail "sdlc.agents.reviewer.gate missing or at the wrong path"
fi
if python3 -c "import yaml" 2>/dev/null; then
  if python3 -c "import yaml;yaml.safe_load(open('vibekit.example.yaml'))" 2>/dev/null; then
    pass "vibekit.example.yaml parses as YAML"
  else
    fail "vibekit.example.yaml is not valid YAML"
  fi
else
  pass "vibekit.example.yaml YAML parse skipped (PyYAML not installed)"
fi

# 13. /sdlc continue must be a registered subcommand — without it awaiting_phase never clears.
if grep -q '`/sdlc continue`' skills/sdlc/SKILL.md; then
  pass "/sdlc continue registered in the subcommand table"
else
  fail "/sdlc continue not in SKILL.md — awaiting_phase would have no exit"
fi

# 14. EXAMPLES.md must show a real chain in BOTH separator forms.
#     Requires phase tokens on both sides — `/sdlc backup-restore` must not satisfy this.
TOK='(prd|plan|implement|impl|verify|review)'
for sep in '\+' '-'; do
  if grep -qE "/sdlc ${TOK}${sep}${TOK}" skills/sdlc/EXAMPLES.md; then
    pass "EXAMPLES.md shows a ${sep//\\/} chain form"
  else
    fail "EXAMPLES.md has no ${sep//\\/} chain example with real phase tokens on both sides"
  fi
done

# --- cross-skill edges must be imperative, not descriptive ---
# Explicit expected edges: "<skill> depends on <parent>" — inferring direction from prose
# gives false positives (a parent naming its child in a hierarchy diagram is not a dependency).
EDGES="
coding:coding-agent-guardrails
android-coding:coding
android-coding:coding-agent-guardrails
sdlc:prd
sdlc:planning
sdlc:coding-agent-guardrails
sdlc:coding
report:planning
"
for edge in $EDGES; do
  child="${edge%%:*}"; parent="${edge##*:}"
  f="skills/$child/SKILL.md"
  [ -f "$f" ] || { fail "$f missing (expected edge $child -> $parent)"; continue; }
  # an imperative edge = a single line containing both "read" and the parent skill name
  if grep -iE "\\bread\\b" "$f" | grep -qE "\`$parent\`"; then
    pass "$child -> $parent is an imperative reference"
  else
    fail "$child names $parent as a dependency but no line tells the agent to READ it"
  fi
done

# --- canonical config schema: single source of truth ---
# Three partial copies of the config drifted before this check existed. The example file is
# canonical; any config key named in the docs must exist in it.
if python3 "$SCHEMA_CHECK" >/tmp/vk_schema_out 2>/tmp/vk_schema_err; then
  pass "vibekit.example.yaml parses and covers every documented config key"
else
  fail "$(cat /tmp/vk_schema_out /tmp/vk_schema_err | head -2)"
fi
rm -f /tmp/vk_schema_out /tmp/vk_schema_err

exit "$FAIL"
