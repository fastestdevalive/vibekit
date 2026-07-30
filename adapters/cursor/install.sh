#!/usr/bin/env bash
# Install vibekit skill(s) as Cursor rules (.cursor/rules/<name>.mdc).
#
# Usage: ./install.sh [skill-name] [target-project-dir]
#   target-project-dir defaults to the current directory.
#
# Cursor has no concept of a companion file — a SKILL.md that links to
# GRAMMAR.md/FORMAT.md/etc. would ship those links inert. So every companion
# linked from SKILL.md (e.g. `[GRAMMAR.md](./GRAMMAR.md)`) is inlined into
# the single .mdc file, under a `## ── <NAME>.md ──` separator, excluding
# evals/ and CONTRIBUTING.md (never shipped by any adapter).
#
# TODO: parse skill.md frontmatter and emit a proper .mdc file with
# `description` and `globs` fields. For now this is a stub that copies
# skill.md (+ companions) verbatim.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

SKILL="${1:-all}"
TARGET="${2:-$(pwd)}"
RULES_DIR="$TARGET/.cursor/rules"

mkdir -p "$RULES_DIR"

# render_skill <skill-dir> — SKILL.md, then every linked companion inlined.
render_skill() {
  local dir="$1"
  local src="$dir/SKILL.md"
  echo "<!-- vibekit: companions are inlined below — Cursor has no companion-file mechanism -->"
  cat "$src"
  local companions
  companions="$(grep -oE '\]\(\./[A-Za-z0-9_.-]+\.md\)' "$src" 2>/dev/null \
    | sed -E 's/^\]\(\.\///; s/\)$//' | awk '!seen[$0]++' || true)"
  local c
  for c in $companions; do
    case "$c" in
      CONTRIBUTING.md) continue ;;
    esac
    if [[ -f "$dir/$c" ]]; then
      echo
      echo "## ── $c ──"
      echo
      cat "$dir/$c"
    fi
  done
}

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name/SKILL.md"
  if [[ ! -f "$src" ]]; then
    echo "Error: no SKILL.md for $name" >&2
    return 1
  fi
  render_skill "$SKILLS_SRC/$name" > "$RULES_DIR/$name.mdc"
  echo "wrote  $RULES_DIR/$name.mdc"
}

if [[ "$SKILL" == "all" ]]; then
  for d in "$SKILLS_SRC"/*/; do
    name="$(basename "$d")"
    # A dir with no SKILL.md is not a skill (e.g. a companion-only or probe dir) — skip, don't abort.
    if [[ ! -f "$d/SKILL.md" ]]; then
      echo "skip   $name (no SKILL.md)"
      continue
    fi
    install_one "$name"
  done
else
  install_one "$SKILL"
fi

echo
echo "Done. Installed into: $RULES_DIR"
echo "Note: this adapter is a stub — frontmatter is not yet translated to Cursor's .mdc schema."
