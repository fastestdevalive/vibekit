#!/usr/bin/env bash
# Install vibekit skill(s) into a Gemini CLI project.
#
# Usage: ./install.sh [skill-name] [target-project-dir]
#   target-project-dir defaults to the current directory.
#
# Installs to two locations:
#   GEMINI.md              ← context injected into every Gemini session
#   .gemini/commands/      ← registers /skill-name slash commands

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

SKILL="${1:-all}"
TARGET="${2:-$(pwd)}"
GEMINI_MD="$TARGET/GEMINI.md"
COMMANDS_DIR="$TARGET/.gemini/commands"

touch "$GEMINI_MD"
mkdir -p "$COMMANDS_DIR"

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name/skill.md"
  if [[ ! -f "$src" ]]; then
    echo "Error: no skill.md for $name" >&2
    return 1
  fi

  # 1. Append skill body to GEMINI.md (idempotent via sentinel comment)
  if grep -q "<!-- vibekit:$name -->" "$GEMINI_MD" 2>/dev/null; then
    echo "skip   $name (already present in GEMINI.md)"
  else
    {
      echo
      echo "<!-- vibekit:$name -->"
      cat "$src"
      echo "<!-- /vibekit:$name -->"
    } >> "$GEMINI_MD"
    echo "appended $name → GEMINI.md"
  fi

  # 2. Emit .gemini/commands/<name>.md for slash-command trigger (e.g. /plan)
  #    Gemini CLI loads *.md files from .gemini/commands/ as custom slash commands.
  local cmd_file="$COMMANDS_DIR/$name.md"
  if [[ -f "$cmd_file" ]]; then
    echo "skip   $cmd_file (already exists)"
  else
    local desc
    desc=$(grep '^description:' "$src" | head -1 | sed 's/^description:[[:space:]]*//')
    {
      echo "# /$name"
      [[ -n "$desc" ]] && echo && echo "$desc"
      echo
      cat "$src"
    } > "$cmd_file"
    echo "wrote  $cmd_file"
  fi
}

if [[ "$SKILL" == "all" ]]; then
  for d in "$SKILLS_SRC"/*/; do
    install_one "$(basename "$d")"
  done
else
  install_one "$SKILL"
fi

echo
echo "Done."
echo "  Context : $GEMINI_MD"
echo "  Commands: $COMMANDS_DIR"
