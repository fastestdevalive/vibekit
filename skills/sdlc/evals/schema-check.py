#!/usr/bin/env python3
"""Canonical-schema check for .vibekit.example.yaml.

Scope: the CONFIG schema only. `.sdlc-state.yaml` is a separate, runtime schema whose keys
(awaiting_phase, spawned_from, last_completed, ...) are deliberately not checked here.

Matches fully-qualified `sdlc.*` / `screenshots.*` references only. A bare-snake_case
heuristic was tried and rejected: it matched state keys and Android string names, producing
false failures. Precision beats recall for a check that gates every PR.
"""
import re, sys, glob, yaml

try:
    ex = yaml.safe_load(open(".vibekit.example.yaml"))
except Exception as e:
    print(f".vibekit.example.yaml is not valid YAML: {e}"); sys.exit(1)

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
sys.exit(0)
