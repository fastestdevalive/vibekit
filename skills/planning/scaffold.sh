#!/usr/bin/env bash
# Scaffold a project for vibekit planning:
#   .feature-plans/{pending,wip,done}/  ← plan directories + template
#   AGENTS.md                           ← root agent guide (planning + guardrails)
#   CLAUDE.md                           ← same, for Claude Code
#
# Usage: ./scaffold.sh [target-project-dir]
#   target-project-dir defaults to the current directory.

set -euo pipefail

TARGET="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ ! -d "$TARGET" ]]; then
  echo "Error: target directory does not exist: $TARGET" >&2
  exit 1
fi

PLANS_DIR="$TARGET/.feature-plans"

# 1. Create .feature-plans directories
mkdir -p "$PLANS_DIR/pending" "$PLANS_DIR/wip" "$PLANS_DIR/done"

# 2. Copy planning template + plan-format guide (don't overwrite user customizations)
for f in _plan_sample_format.md AGENTS.md; do
  if [[ -e "$PLANS_DIR/$f" ]]; then
    echo "skip   $PLANS_DIR/$f (already exists)"
  else
    cp "$SCRIPT_DIR/$f" "$PLANS_DIR/$f"
    echo "wrote  $PLANS_DIR/$f"
  fi
done

# 3. Copy PRD template into .feature-plans/ (don't overwrite user customizations)
PRD_SAMPLE="$REPO_ROOT/skills/prd/_prd_sample_format.md"
if [[ -f "$PRD_SAMPLE" ]]; then
  if [[ -e "$PLANS_DIR/_prd_sample_format.md" ]]; then
    echo "skip   $PLANS_DIR/_prd_sample_format.md (already exists)"
  else
    cp "$PRD_SAMPLE" "$PLANS_DIR/_prd_sample_format.md"
    echo "wrote  $PLANS_DIR/_prd_sample_format.md"
  fi
fi

# 3. Generate root AGENTS.md and CLAUDE.md (project-level agent context)
#    These reference both the planning and guardrails skills.
#    Skip if the file already exists to avoid overwriting project customizations.
ROOT_AGENT_CONTENT="# Agent guide

## SWE workflow

\`\`\`
PRD  →  Technical Plan  →  Implementation
\`\`\`

- **PRD** (\`.feature-plans/pending/prd-<slug>.md\`): required for large features (new UX flows, data model changes). Use \`.feature-plans/_prd_sample_format.md\` as the template.
- **Technical plan** (\`.feature-plans/pending/<slug>.md\`): required for all non-trivial work. Use \`.feature-plans/_plan_sample_format.md\` as the template.
- For small changes (bug fixes, single-screen tweaks): skip the PRD.

Plans live in \`.feature-plans/\` (\`pending/\`, \`wip/\`, \`done/\`).

- Follow format rules in \`.feature-plans/AGENTS.md\`
- Move plans: \`pending/\` → \`wip/\` when work starts → \`done/\` when complete

## File size limits

- **Source files: hard ceiling at 1,500 lines.** Split files that approach this limit before merging.
- **Agent guide files** (AGENTS.md, CLAUDE.md, GEMINI.md, files under \`agents/\`): max **200 lines**. Split into sub-guides when the limit approaches.

## Code organization

- Organize by **feature**, not by layer.
- Sub-components of a screen belong in \`components/\` relative to that screen.
- Cross-feature reusables belong in \`common/\` (or \`shared/\`).
- When a class would exceed the line limit, extract logic into a companion \`<Name>Logic\` file in the same package.

## VCS discipline

- **Never \`git commit\` or \`git add\` without explicit user permission.**
- Stage only files relevant to the task — not everything in the working tree.

## Build behavior

- **Ignore build warnings.** Only errors need to be fixed.
- Do not change working code just to silence a warning.
"

for dest_file in "$TARGET/AGENTS.md" "$TARGET/CLAUDE.md"; do
  if [[ -e "$dest_file" ]]; then
    echo "skip   $dest_file (already exists)"
  else
    printf '%s' "$ROOT_AGENT_CONTENT" > "$dest_file"
    echo "wrote  $dest_file"
  fi
done

echo
echo "Done. Scaffolded in: $TARGET"
echo "Next: copy .feature-plans/_plan_sample_format.md to .feature-plans/pending/<your-slug>.md and start filling it in."
