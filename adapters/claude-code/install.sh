#!/usr/bin/env bash
# Install vibekit skill(s) into Claude Code's user skills directory.
#
# Usage: ./install.sh [skill-name]
#   skill-name: name of a skill under ../../skills/, or "all" (default)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

SKILL="${1:-all}"

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name"
  local dest="$CLAUDE_SKILLS_DIR/$name"

  if [[ ! -d "$src" ]]; then
    echo "Error: no such skill: $name" >&2
    return 1
  fi

  mkdir -p "$dest"

  # Claude Code expects SKILL.md (uppercase). Map skill.md → SKILL.md.
  if [[ -f "$src/skill.md" ]]; then
    cp "$src/skill.md" "$dest/SKILL.md"
    echo "wrote  $dest/SKILL.md"
  fi

  # Copy any other resources alongside (templates, scripts, etc.)
  for f in "$src"/*; do
    [[ -e "$f" ]] || continue
    base="$(basename "$f")"
    [[ "$base" == "skill.md" ]] && continue
    cp -R "$f" "$dest/"
    echo "wrote  $dest/$base"
  done
}

if [[ "$SKILL" == "all" ]]; then
  for d in "$SKILLS_SRC"/*/; do
    install_one "$(basename "$d")"
  done
else
  install_one "$SKILL"
fi

echo
echo "Done. Installed into: $CLAUDE_SKILLS_DIR"
