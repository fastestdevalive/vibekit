#!/usr/bin/env bash
# Scaffold .feature-plans/{pending,wip,done}/ in a target project
# and copy the planning template + agent guide.
#
# Usage: ./scaffold.sh [target-project-dir]
#   target-project-dir defaults to the current directory.

set -euo pipefail

TARGET="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$TARGET" ]]; then
  echo "Error: target directory does not exist: $TARGET" >&2
  exit 1
fi

PLANS_DIR="$TARGET/.feature-plans"

mkdir -p "$PLANS_DIR/pending" "$PLANS_DIR/wip" "$PLANS_DIR/done"

# Copy template + guide if not already present (don't overwrite user customizations)
for f in _plan_sample_format.md AGENTS.md; do
  if [[ -e "$PLANS_DIR/$f" ]]; then
    echo "skip   $PLANS_DIR/$f (already exists)"
  else
    cp "$SCRIPT_DIR/$f" "$PLANS_DIR/$f"
    echo "wrote  $PLANS_DIR/$f"
  fi
done

echo
echo "Done. .feature-plans/ scaffolded in: $TARGET"
echo "Next: copy _plan_sample_format.md to pending/<your-slug>.md and start filling it in."
