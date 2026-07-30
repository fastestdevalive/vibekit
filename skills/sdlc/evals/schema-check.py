#!/usr/bin/env python3
"""Canonical-schema check for vibekit.example.yaml AND sdlc-state.example.yaml.

Two independent schemas, two independent checks:
  1. CONFIG  — vibekit.example.yaml. Matches fully-qualified `sdlc.*` / `screenshots.*`
     references only. A bare-snake_case heuristic was tried and rejected: it matched state
     keys and Android string names, producing false failures. Precision beats recall for a
     check that gates every PR.
  2. STATE   — sdlc-state.example.yaml. `.sdlc-state.yaml` keys are documented bare
     (`awaiting_phase`, `spawned_from`, ...), never prefixed, so the fully-qualified
     approach from (1) doesn't apply. Instead: a hand-curated set of the state field names
     the sdlc docs actually document (see STATE_KEYS_DOCUMENTED below) is checked against
     every dict key present anywhere in the canonical state schema (including nested inside
     `subfeatures[]` list items). A regex free-for-all over bare identifiers was rejected
     here too — words like "mode", "id", "plan" collide with unrelated prose.
"""
import re, sys, glob, yaml

try:
    ex = yaml.safe_load(open("vibekit.example.yaml"))
except Exception as e:
    print(f"vibekit.example.yaml is not valid YAML: {e}"); sys.exit(1)

def flat(d, prefix=""):
    out = set()
    for k, v in (d or {}).items():
        out.add(prefix + k)
        if isinstance(v, dict):
            out |= flat(v, prefix + k + ".")
    return out

have = flat(ex)
referenced, bare = set(), set()
for f in glob.glob("skills/*/[A-Z]*.md") + glob.glob("skills/*/evals/*.md"):
    txt = open(f).read()
    referenced |= {m.rstrip(".") for m in
                   re.findall(r"`(sdlc\.[a-z_.]+|screenshots\.[a-z_]+)`", txt)}
    # docs reference some keys bare (`max_iterations`) and some fully-qualified.
    # Bare names are ambiguous enough to be useless for the forward check, but fine
    # for proving a key IS documented — no two config leaves share a name.
    bare |= set(re.findall(r"`([a-z][a-z_]*)`", txt))

missing = sorted(k for k in referenced if k not in have)
if missing:
    print("referenced in docs, absent from canonical schema: " + " ".join(missing)); sys.exit(1)

# reverse direction: a config key nobody documents is dead weight
groups = {k for k in have if any(o.startswith(k + ".") for o in have)}
dead = sorted(k for k in have - groups
              if k not in referenced and k.split(".")[-1] not in bare and k.count(".") >= 2)
# Advisory only. Docs legitimately describe some keys in prose without backticking them,
# so failing on this would gate CI on writing style rather than on drift. The forward
# check above is the one that catches the real bug (a key documented but not in the schema).
if dead:
    print("note: in schema, not backticked in docs: " + " ".join(dead))

# --------------------------------------------------------------------------------- STATE

STATE_SCHEMA_FILE = "sdlc-state.example.yaml"
try:
    state = yaml.safe_load(open(STATE_SCHEMA_FILE))
except Exception as e:
    print(f"{STATE_SCHEMA_FILE} is not valid YAML: {e}"); sys.exit(1)

def all_keys(obj):
    """Every dict key found anywhere in a nested dict/list structure (any depth)."""
    out = set()
    if isinstance(obj, dict):
        for k, v in obj.items():
            out.add(k)
            out |= all_keys(v)
    elif isinstance(obj, list):
        for item in obj:
            out |= all_keys(item)
    return out

state_have = all_keys(state)

# Field names skills/sdlc/*.md actually document as part of `.sdlc-state.yaml`
# (SKILL.md's schema block/pointer, PHASES.md's per-mode rules, GRAMMAR.md's awaiting
# lifecycle). Keep in sync with those docs — this check exists so a key removed from the
# canonical schema, or renamed there, is caught before it silently drifts from the docs.
STATE_KEYS_DOCUMENTED = {
    "feature", "worktree", "created", "master", "prd", "plan",
    "current_subfeature", "subfeatures", "id", "origin", "spawned_from",
    "mode", "last_completed", "awaiting_phase", "awaiting_artifact",
    "phase_chain", "superseded_reason", "parked_reason", "handoff",
    "next_item", "returned_at", "verified_by", "commit",
}
missing_state = sorted(k for k in STATE_KEYS_DOCUMENTED if k not in state_have)
if missing_state:
    print("state key documented in skills/sdlc/*.md, absent from canonical state schema: "
          + " ".join(missing_state))
    sys.exit(1)

sys.exit(0)
