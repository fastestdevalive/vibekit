#!/usr/bin/env bash
# Install vibekit skill(s) as Cursor rules (.cursor/rules/<name>.mdc).
#
# Usage: ./install.sh [skill-name] [target-project-dir]
#   target-project-dir defaults to the current directory.
#
# TODO: parse skill.md frontmatter and emit a proper .mdc file with
# `description` and `globs` fields. For now this is a stub that copies
# skill.md verbatim.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

SKILL="${1:-all}"
TARGET="${2:-$(pwd)}"
RULES_DIR="$TARGET/.cursor/rules"

mkdir -p "$RULES_DIR"

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name/skill.md"
  if [[ ! -f "$src" ]]; then
    echo "Error: no skill.md for $name" >&2
    return 1
  fi
  cp "$src" "$RULES_DIR/$name.mdc"
  echo "wrote  $RULES_DIR/$name.mdc"
}

if [[ "$SKILL" == "all" ]]; then
  for d in "$SKILLS_SRC"/*/; do
    install_one "$(basename "$d")"
  done
else
  install_one "$SKILL"
fi

echo
echo "Done. Installed into: $RULES_DIR"
echo "Note: this adapter is a stub — frontmatter is not yet translated to Cursor's .mdc schema."
