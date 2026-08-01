#!/usr/bin/env bash
# Install every vibekit skill into an agy (Antigravity) project's workspace
# customization layout (.agents/skills/<name>/SKILL.md), or globally.
#
# Usage: ./install.sh [--project=<dir> | --global]
#   --project=:  target project directory; defaults to the current directory.
#                This is the DEFAULT mode.
#   --global:    install to a user-level dir instead — see caveat below.
#
# Project-scoped (default) — documented and reliable: agy walks from CWD up to
# the repo root looking for .agents/ (or .agent/, _agents/, _agent/), then reads
# <found-dir>/skills/<name>/SKILL.md.
#
# --global — CAVEAT: Antigravity's own docs disagree on the global path across
# its CLI/IDE editions (candidates seen: ~/.gemini/antigravity/skills/,
# ~/.gemini/antigravity-cli/skills/, ~/.gemini/skills/). The one path an
# independent empirical test found working across CLI, IDE, and "Antigravity 2.0"
# is ~/.gemini/config/skills/<name>/ (Mete Atamel, Medium, "Where does Antigravity
# look for Agent Skills?", 2026) — that's what --global writes to here. Treat it
# as best-effort: if skills don't show up, fall back to --project=<dir>.
#
# Skills use the same progressive-disclosure model as Claude Code (only
# name+description load by default), so SKILL.md files install verbatim — no
# field translation needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

PROJECT_DIR=""
GLOBAL=0
for arg in "$@"; do
  case "$arg" in
    --project=*|--dir=*) PROJECT_DIR="${arg#--*=}" ;;
    --global) GLOBAL=1 ;;
    *)
      echo "Error: unrecognized argument '$arg' (expected --project=<dir> or --global)" >&2
      exit 1
      ;;
  esac
done

if [[ $GLOBAL -eq 1 ]]; then
  echo "Note: --global uses an empirically-verified but UNOFFICIAL path" >&2
  echo "(~/.gemini/config/skills/) — Antigravity's own docs disagree with each" >&2
  echo "other on this. If skills don't show up, retry with --project=<dir>." >&2
  AGENTS_SKILLS_DIR="$HOME/.gemini/config/skills"
else
  TARGET="${PROJECT_DIR:-$(pwd)}"
  AGENTS_SKILLS_DIR="$TARGET/.agents/skills"
fi

install_one() {
  local name="$1"
  local src="$SKILLS_SRC/$name"
  local dest="$AGENTS_SKILLS_DIR/$name"

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
echo "Done. Installed into: $AGENTS_SKILLS_DIR"
