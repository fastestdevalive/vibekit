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

# Stale-install cleanup: skills renamed in vibekit still linger under their old
# name in ~/.claude/skills/ until removed explicitly.
STALE_SKILLS=(guardrails)
for stale in "${STALE_SKILLS[@]}"; do
  stale_dir="$CLAUDE_SKILLS_DIR/$stale"
  if [[ -e "$stale_dir" ]]; then
    rm -rf "$stale_dir"
    echo "removed stale $stale_dir"
  fi
done

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name"
  local dest="$CLAUDE_SKILLS_DIR/$name"

  if [[ ! -d "$src" ]]; then
    echo "Error: no such skill: $name" >&2
    return 1
  fi

  # Sync, don't merge: files removed or renamed in vibekit must not linger in the
  # install. A stale companion (e.g. an old AGENTS.md) would sit alongside its
  # replacement and hand the agent two contradictory rule sets.
  if [[ -d "$dest" ]]; then
    for old in "$dest"/*; do
      [[ -e "$old" ]] || continue
      oldbase="$(basename "$old")"
      if [[ ! -e "$src/$oldbase" ]]; then
        rm -rf "$old"
        echo "removed stale $dest/$oldbase"
      fi
    done
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
    install_one "$(basename "$d")"
  done
else
  install_one "$SKILL"
fi

echo
echo "Done. Installed into: $CLAUDE_SKILLS_DIR"
