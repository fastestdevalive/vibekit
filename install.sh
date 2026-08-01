#!/usr/bin/env bash
# Top-level vibekit installer. Dispatches to the right per-tool adapter.
# Always installs every skill — there is no per-skill option.
#
# Usage: ./install.sh <tool> [--project=<dir>]
#   tool: claude-code | cursor | agy | opencode

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <claude-code|cursor|agy|opencode> [--project=<dir>]" >&2
  exit 1
fi

TOOL="$1"
shift
ADAPTER="$SCRIPT_DIR/adapters/$TOOL/install.sh"

if [[ ! -x "$ADAPTER" ]]; then
  echo "Error: no adapter for tool '$TOOL' (looked for $ADAPTER)" >&2
  exit 1
fi

exec "$ADAPTER" "$@"
