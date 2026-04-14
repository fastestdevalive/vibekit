# vibekit — Agent guide

Toolkit of agentic software-development skills. Skills are plain Markdown, adapted for Claude Code, Cursor, and Gemini CLI via thin per-tool adapters.

## SWE workflow

```
PRD  →  Technical Plan  →  Implementation
```

| Step | When | Skill |
|------|------|-------|
| **PRD** | Large features: new UX flows, multi-screen changes, data model changes | `prd` |
| **Technical plan** | All non-trivial work; always after PRD for large features | `planning` |
| **Guardrails** | Applied continuously on every file touched | `guardrails` |

For small changes (bug fixes, single-screen tweaks, refactors): skip the PRD, write a technical plan or go straight to implementation.

## Skills

| Skill | What it does |
|-------|-------------|
| [`prd`](skills/prd/) | Product requirements — user behavior, options, decisions, screen layouts |
| [`planning`](skills/planning/) | Technical plan — bullet-point, file/line refs, phased checklists + test verification |
| [`guardrails`](skills/guardrails/) | File size limits, code structure, VCS discipline, build behavior |

## Repo layout

```
skills/<name>/
  skill.md                   ← source of truth + YAML frontmatter
  AGENTS.md                  ← agent writing guide for this skill
  _prd_sample_format.md      ← (prd) PRD template
  _plan_sample_format.md     ← (planning) technical plan template
  scaffold.sh                ← (planning) project bootstrapper
adapters/
  claude-code/install.sh     ← → ~/.claude/skills/<name>/
  cursor/install.sh          ← → .cursor/rules/<name>.mdc
  gemini/install.sh          ← → GEMINI.md + .gemini/commands/<name>.md
install.sh                   ← top-level dispatcher
```

## Installing skills into a project

```bash
# Claude Code (installs to ~/.claude/skills/)
./install.sh claude-code

# Gemini CLI (appends to GEMINI.md + emits .gemini/commands/)
./install.sh gemini [target-dir]

# Cursor (.cursor/rules/<name>.mdc)
./install.sh cursor [target-dir]
```

## Scaffolding a new project

```bash
# Creates .feature-plans/, places AGENTS.md + CLAUDE.md in the target project
./skills/planning/scaffold.sh /path/to/your/project
```

## Adding a new skill

1. Create `skills/<name>/skill.md` with YAML frontmatter (`name`, `description`, `version`, `triggers`, `globs`)
2. Add an `AGENTS.md` agent writing guide if the skill has format or style rules
3. All adapters pick up the new skill automatically via directory glob
