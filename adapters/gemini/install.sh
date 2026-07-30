#!/usr/bin/env bash
# Install vibekit skill(s) into a Gemini CLI project.
#
# Usage: ./install.sh [skill-name] [target-project-dir]
#   target-project-dir defaults to the current directory.
#
# Installs to two locations:
#   GEMINI.md              ← context injected into every Gemini session
#   .gemini/commands/      ← registers /skill-name slash commands
#
# Gemini CLI has no companion-file mechanism — a SKILL.md that links to
# GRAMMAR.md/FORMAT.md/etc. would ship those links inert. So every companion
# linked from SKILL.md (e.g. `[GRAMMAR.md](./GRAMMAR.md)`) is inlined into
# both destinations, under a `## ── <NAME>.md ──` separator, excluding
# evals/ and CONTRIBUTING.md (never shipped by any adapter).

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

# render_companions <skill-dir> — every companion linked from SKILL.md, inlined.
render_companions() {
  local dir="$1"
  local src="$dir/SKILL.md"
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
  local skill_dir="$SKILLS_SRC/$name"
  local src="$skill_dir/SKILL.md"
  if [[ ! -f "$src" ]]; then
    echo "Error: no SKILL.md for $name" >&2
    return 1
  fi

  # 1. Append skill body + inlined companions to GEMINI.md (idempotent via sentinel comment)
  if grep -q "<!-- vibekit:$name -->" "$GEMINI_MD" 2>/dev/null; then
    echo "skip   $name (already present in GEMINI.md)"
  else
    {
      echo
      echo "<!-- vibekit:$name -->"
      echo "<!-- companions are inlined below — Gemini CLI has no companion-file mechanism -->"
      cat "$src"
      render_companions "$skill_dir"
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
      echo "<!-- companions are inlined below — Gemini CLI has no companion-file mechanism -->"
      echo
      cat "$src"
      render_companions "$skill_dir"
    } > "$cmd_file"
    echo "wrote  $cmd_file"
  fi
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
echo "Done."
echo "  Context : $GEMINI_MD"
echo "  Commands: $COMMANDS_DIR"
