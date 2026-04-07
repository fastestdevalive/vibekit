#!/usr/bin/env bash
# Install vibekit skill(s) into a Gemini CLI project (GEMINI.md context).
#
# Usage: ./install.sh [skill-name] [target-project-dir]
#   target-project-dir defaults to the current directory.
#
# TODO: optionally emit .gemini/commands/<name>.toml for slash-command triggers.
# For now this is a stub that appends the skill body to GEMINI.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

SKILL="${1:-all}"
TARGET="${2:-$(pwd)}"
GEMINI_MD="$TARGET/GEMINI.md"

touch "$GEMINI_MD"

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name/skill.md"
  if [[ ! -f "$src" ]]; then
    echo "Error: no skill.md for $name" >&2
    return 1
  fi

  if grep -q "<!-- vibekit:$name -->" "$GEMINI_MD" 2>/dev/null; then
    echo "skip   $name (already present in GEMINI.md)"
    return
  fi

  {
    echo
    echo "<!-- vibekit:$name -->"
    cat "$src"
    echo "<!-- /vibekit:$name -->"
  } >> "$GEMINI_MD"
  echo "appended $name → $GEMINI_MD"
}

if [[ "$SKILL" == "all" ]]; then
  for d in "$SKILLS_SRC"/*/; do
    install_one "$(basename "$d")"
  done
else
  install_one "$SKILL"
fi

echo
echo "Done. Updated: $GEMINI_MD"
echo "Note: this adapter is a stub — does not yet emit .gemini/commands/*.toml."
