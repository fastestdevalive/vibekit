#!/usr/bin/env bash
# One-line installer/updater for vibekit.
#
#   curl -fsSL https://raw.githubusercontent.com/fastestdevalive/vibekit/main/scripts/get.sh | bash -s -- claude-code
#
# Clones vibekit into ~/.vibekit (or pulls latest if already cloned), then
# runs the top-level installer for the given tool. Safe to re-run any time —
# re-running this exact command is how you update to the latest version.
#
# Always installs every skill — there is no per-skill option.
#
# Usage: get.sh <claude-code|cursor|agy|opencode> [--project=<dir>]
#   tool:        required. claude-code | cursor | agy | opencode
#   --project=:  optional. claude-code and opencode install GLOBALLY by
#                default (no path needed); cursor and agy default to the
#                current directory — pass --project=<dir> to target a
#                different one. See README.md's Getting started section for
#                why the default scope differs per tool.

set -euo pipefail

REPO_URL="https://github.com/fastestdevalive/vibekit.git"
INSTALL_DIR="${VIBEKIT_HOME:-$HOME/.vibekit}"

if [[ $# -lt 1 ]]; then
  echo "Usage: get.sh <claude-code|cursor|agy|opencode> [--project=<dir>]" >&2
  exit 1
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "Updating vibekit in $INSTALL_DIR ..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "Cloning vibekit into $INSTALL_DIR ..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

exec "$INSTALL_DIR/install.sh" "$@"
