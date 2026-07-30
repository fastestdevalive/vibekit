#!/usr/bin/env bash
# Install vibekit skill(s) into an agy (Antigravity) project's workspace
# customization layout (.agents/skills/<name>/SKILL.md).
#
# Usage: ./install.sh [skill-name] [target-project-dir]
#   skill-name:         name of a skill under ../../skills/, or "all" (default)
#   target-project-dir: defaults to the current directory
#
# agy discovers skills by walking from CWD up to the repo root looking for
# .agents/ (or .agent/, _agents/, _agent/), then reading
# <found-dir>/skills/<name>/SKILL.md. Skills use the same progressive-disclosure
# model as Claude Code (only name+description load by default), so SKILL.md
# files install verbatim — no field translation needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

SKILL="${1:-all}"
TARGET="${2:-$(pwd)}"
AGENTS_SKILLS_DIR="$TARGET/.agents/skills"

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name"
  local dest="$AGENTS_SKILLS_DIR/$name"

  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "Error: no SKILL.md for $name" >&2
    return 1
  fi

  mkdir -p "$dest"

  # Copy all files, including SKILL.md — but not maintainer-only / non-shipping entries.
  for f in "$src"/*; do
    [[ -e "$f" ]] || continue
    base="$(basename "$f")"
    case "$base" in
      evals|CONTRIBUTING.md) echo "skip   $src/$base (not shipped)"; continue ;;
    esac
    cp -R "$f" "$dest/"
    echo "wrote  $dest/$base"
  done
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
echo "Done. Installed into: $AGENTS_SKILLS_DIR"
