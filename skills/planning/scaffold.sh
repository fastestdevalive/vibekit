#!/usr/bin/env bash
# Scaffold a project for vibekit planning:
#   .vibekit/feature-plans/{pending,wip,done}/  ← plan directories + template
#   AGENTS.md                                   ← root agent guide (planning + coding-agent-guardrails)
#   CLAUDE.md                                   ← same, for Claude Code
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

PLANS_DIR="$TARGET/.vibekit/feature-plans"

# 1. Create .vibekit/feature-plans directories + .gitkeep (git does not track empty dirs)
mkdir -p "$PLANS_DIR/pending" "$PLANS_DIR/wip" "$PLANS_DIR/done"
for d in pending wip done; do
  touch "$PLANS_DIR/$d/.gitkeep"
done
echo "wrote  $PLANS_DIR/{pending,wip,done}/.gitkeep"

# 1b. Gitignore transient screenshots + local config by default (never committed unless opted in)
GITIGNORE="$TARGET/.vibekit/.gitignore"
if [[ -e "$GITIGNORE" ]]; then
  echo "skip   $GITIGNORE (already exists)"
else
  printf '%s\n' 'config.yaml' '**/screenshots/' > "$GITIGNORE"
  echo "wrote  $GITIGNORE"
fi

# 2. Copy planning templates + plan-format guides (don't overwrite user customizations)
for f in _template_arch.md _template_plan.md FORMAT.md SECTIONS.md; do
  if [[ -e "$PLANS_DIR/$f" ]]; then
    echo "skip   $PLANS_DIR/$f (already exists)"
  else
    cp "$SCRIPT_DIR/$f" "$PLANS_DIR/$f"
    echo "wrote  $PLANS_DIR/$f"
  fi
done

# 3. Copy PRD template into .vibekit/feature-plans/ (don't overwrite user customizations)
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
#    These reference both the planning and coding-agent-guardrails skills.
#    Skip if the file already exists to avoid overwriting project customizations.
ROOT_AGENT_CONTENT="# Agent guide

## SWE workflow

\`\`\`
PRD  →  Technical Plan  →  Implementation
\`\`\`

- **PRD** (\`.vibekit/feature-plans/pending/<feature>/prd-<feature>.md\`): required for large features (new UX flows, data model changes). Use \`.vibekit/feature-plans/_prd_sample_format.md\` as the template.
- **Technical plan** (\`.vibekit/feature-plans/pending/<feature>/plan-<feature>.md\`): required for all non-trivial work. Use \`.vibekit/feature-plans/_template_plan.md\` (the default) or \`.vibekit/feature-plans/_template_arch.md\` (rare — system-level decomposition) as the template.
- For small changes (bug fixes, single-screen tweaks): skip the PRD.

## Feature-plan directory layout (primary — directory mode)

\`\`\`
.vibekit/feature-plans/<state>/<feature>/     ← state: pending | wip | done
  prd-<feature>.md                    ← master PRD (optional)
  arch-<feature>.md                   ← master arch (rare — only if system-level decomposition is needed)
  plan-<feature>.md                   ← master plan
  NN-<subfeature>/
    plan-<NN>-<feature>-<subfeature>.md
    screenshots/                      ← transient by default, gitignored
\`\`\`

- Simple features skip sub-feature dirs — just \`plan-<feature>.md\` at the feature root
- **Backward compat:** a flat \`.vibekit/feature-plans/pending/<slug>.md\` file still works for existing plans
- Follow format rules in \`.vibekit/feature-plans/FORMAT.md\` and section templates in \`.vibekit/feature-plans/SECTIONS.md\`
- Move the whole feature directory: \`pending/\` → \`wip/\` when work starts → \`done/\` when complete

### File naming convention

| Doc | Pattern | Example |
|-----|---------|---------|
| Master PRD | \`prd-<feature>.md\` | \`prd-auth-flow.md\` |
| Master plan | \`plan-<feature>.md\` | \`plan-auth-flow.md\` |
| Master arch _(rare)_ | \`arch-<feature>.md\` | \`arch-auth-flow.md\` |
| Sub-feature PRD | \`prd-<NN>-<feature>-<subfeature>.md\` | \`prd-02-auth-flow-api.md\` |
| Sub-feature plan | \`plan-<NN>-<feature>-<subfeature>.md\` | \`plan-02-auth-flow-api.md\` |

- \`NN\` is assigned once and never renumbered — new sub-features always append

## File size limits

- **Source files: hard ceiling at 1,500 lines.** Split files that approach this limit before merging.
- **Doc files: cap by when the file loads, not what it is.** Always-loaded (SKILL.md, AGENTS.md, CLAUDE.md, GEMINI.md): max **400 lines**. On-demand companions (FORMAT.md, SECTIONS.md, PHASES.md, GRAMMAR.md, EXAMPLES.md): max **600 lines**. Templates (\`_template_*.md\`): no cap. Split into sub-guides when the limit approaches.

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
echo
echo "Directory layout for a new feature (primary — directory mode):"
echo "  .vibekit/feature-plans/pending/<feature>/"
echo "  ├── prd-<feature>.md                     (optional — master PRD)"
echo "  ├── arch-<feature>.md                    (rare — master arch, only if system-level decomposition is needed)"
echo "  ├── plan-<feature>.md                    (master plan)"
echo "  └── 01-<subfeature>/"
echo "      └── plan-01-<feature>-<subfeature>.md"
echo
echo "Next: mkdir -p .vibekit/feature-plans/pending/<your-feature> && copy"
echo "  .vibekit/feature-plans/_template_plan.md (or _template_arch.md if this feature needs system-level decomposition)"
echo "  to .vibekit/feature-plans/pending/<your-feature>/plan-<your-feature>.md and start filling it in."
