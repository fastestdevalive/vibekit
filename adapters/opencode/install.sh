#!/usr/bin/env bash
# Install every vibekit skill into OpenCode (opencode.ai), globally by default.
#
# Usage: ./install.sh [--project=<dir>]
#   --project=:  install scoped to one project instead of globally
#
# OpenCode has a native Skills system with the same progressive-disclosure
# model as Claude Code (only name+description loaded by default; full
# SKILL.md pulled on demand via a `skill` tool call) — confirmed at
# https://opencode.ai/docs/skills.md. It reads skill dirs from BOTH a global
# and a project location:
#   global : ~/.config/opencode/skills/<name>/SKILL.md
#   project: <dir>/.opencode/skills/<name>/SKILL.md
# So this adapter installs GLOBALLY by default — no per-project step needed.
# Pass --project=<dir> to scope to one project.
#
# Note: OpenCode's docs say it *also* auto-discovers `~/.claude/skills/` and
# `~/.agents/skills/` (and their project-local equivalents) for interop — so
# a Claude Code or agy install of vibekit may already be visible to OpenCode
# with zero extra steps. This adapter targets OpenCode's own native
# `skills/` dir so the install doesn't depend on that cross-tool behavior.
#
# SKILL.md files (and linked companions) install verbatim, same as Claude
# Code/agy — no field translation or inlining needed, since OpenCode is a
# full agent with file-read tools, not a text-injection-only context format.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

PROJECT_DIR=""
for arg in "$@"; do
  case "$arg" in
    --project=*|--dir=*) PROJECT_DIR="${arg#--*=}" ;;
    --global) PROJECT_DIR="" ;;  # explicit no-op — global is already the default
    *)
      echo "Error: unrecognized argument '$arg' (expected --project=<dir>)" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$PROJECT_DIR" ]]; then
  OPENCODE_SKILLS_DIR="$PROJECT_DIR/.opencode/skills"
else
  OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skills"
fi

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name"
  local dest="$OPENCODE_SKILLS_DIR/$name"

  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "Error: no SKILL.md for $name" >&2
    return 1
  fi

  # Sync, don't merge: a file renamed or removed in vibekit must not linger here.
  # A stale companion would sit beside its replacement and hand the agent two rule sets.
  if [[ -d "$dest" ]]; then
    for old in "$dest"/*; do
      [[ -e "$old" ]] || continue
      oldbase="$(basename "$old")"
      if [[ ! -e "$src/$oldbase" ]]; then
        rm -rf "$old"; echo "removed stale $dest/$oldbase"
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

for d in "$SKILLS_SRC"/*/; do
  name="$(basename "$d")"
  # A dir with no SKILL.md is not a skill (e.g. a companion-only or probe dir) — skip, don't abort.
  if [[ ! -f "$d/SKILL.md" ]]; then
    echo "skip   $name (no SKILL.md)"
    continue
  fi
  install_one "$name"
done

echo
if [[ -n "$PROJECT_DIR" ]]; then
  echo "Done. Installed scoped to project: $PROJECT_DIR"
else
  echo "Done. Installed globally — available in every OpenCode project."
fi
echo "  Skills: $OPENCODE_SKILLS_DIR"
