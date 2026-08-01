# vibekit — Agent guide

Toolkit of agentic software-development skills. Skills are plain Markdown, adapted for Claude Code, Cursor, agy (Antigravity), and OpenCode via thin per-tool adapters.

## SWE workflow

```
PRD  →  Technical Plan  →  Implementation
```

| Step | When | Skill |
|------|------|-------|
| **PRD** | Large features: new UX flows, multi-screen changes, data model changes | `prd` |
| **Technical plan** | All non-trivial work; always after PRD for large features | `planning` |
| **Guardrails** | Applied continuously on every file touched | `coding-agent-guardrails` |

For small changes (bug fixes, single-screen tweaks, refactors): skip the PRD, write a technical plan or go straight to implementation.

## Skills

| Skill | What it does |
|-------|-------------|
| [`prd`](skills/prd/) | Product requirements — user behavior, options, decisions, screen layouts |
| [`planning`](skills/planning/) | Technical plan — bullet-point, file/line refs, phased checklists + test verification |
| [`coding-agent-guardrails`](skills/coding-agent-guardrails/) | File size limits, code structure, VCS discipline, build behavior |
| [`report`](skills/report/) | One-shot investigation → findings document — no state, no checklist, no phases |

## Repo layout

```
skills/<name>/
  SKILL.md                              ← entry point + YAML frontmatter, ALWAYS read
  FORMAT.md                             ← output format rules (planning, prd) — linked from SKILL.md
  SECTIONS.md                           ← per-section templates (planning) — linked from SKILL.md
  PHASES.md                             ← per-phase agent behavior (sdlc) — linked from SKILL.md
  CONTRIBUTING.md                       ← maintainer-only notes — EXCLUDED from installs
  _prd_sample_format.md                 ← (prd) PRD template
  _template_arch.md                     ← (planning) arch template — rare, system-level decomposition
  _template_plan.md                     ← (planning) plan template — the default
  scaffold.sh                           ← (planning) project bootstrapper
  _template_report.md                   ← (report) findings-doc template — linked from SKILL.md
adapters/
  claude-code/install.sh     ← → ~/.claude/skills/<name>/
  cursor/install.sh          ← → .cursor/rules/<name>.mdc
  agy/install.sh             ← → .agents/skills/<name>/
  opencode/install.sh        ← → ~/.config/opencode/skills/<name>/
install.sh                   ← top-level dispatcher
```

### Companion-file convention

- `AGENTS.md` is retired as a skill filename — one filename, two conflicting audiences (agent-facing rules vs maintainer notes)
- Every companion file is **named for its content** and **linked from `SKILL.md`** — an unlinked file is never loaded
- `CONTRIBUTING.md` is reserved for maintainer-only docs ("what belongs in this skill") and is excluded from adapter installs
- Pure rule skills (`coding-agent-guardrails`, `android-coding`) need no companion — `SKILL.md` is the whole skill

## Feature-plan directory layout

```
.vibekit/feature-plans/<state>/<feature>/     ← state: pending | wip | done
  prd-<feature>.md                    ← master PRD (optional)
  arch-<feature>.md                   ← master arch (rare — only if system-level decomposition is needed)
  plan-<feature>.md                   ← master plan
  NN-<subfeature>/
    plan-<NN>-<feature>-<subfeature>.md
    screenshots/                      ← transient by default, gitignored
```

- Simple features skip the sub-feature dirs — just `plan-<feature>.md` at the feature root
- Backward compat: flat `pending/<slug>.md` files still work

## Reports directory layout

```
.vibekit/reports/
  YYYY-MM-DD-<slug>.md                  ← flat report, no screenshots
  YYYY-MM-DD-<slug>/
    report.md
    screenshots/                        ← gitignored unless permanent
```

- Not under `.vibekit/feature-plans/` — a report is a dated snapshot, not a plan with a lifecycle
- Never edited in place — superseding a report means writing a new dated one

## Installing skills into a project

```bash
# Claude Code — global, installs to ~/.claude/skills/
./install.sh claude-code

# OpenCode — global by default (~/.config/opencode/skills/<name>/);
# pass --project=<dir> to scope to one project instead
./install.sh opencode [--project=<dir>]

# Cursor — project-scoped (.cursor/rules/<name>.mdc); no scriptable global exists
./install.sh cursor [--project=<dir>]

# agy (Antigravity) — project-scoped (.agents/skills/<name>/) by default
./install.sh agy [--project=<dir>]
```

Every installer installs **all skills** — there is no per-skill option.

## Scaffolding a new project

```bash
# Creates .vibekit/feature-plans/, places AGENTS.md + CLAUDE.md in the target project
./skills/planning/scaffold.sh /path/to/your/project
```

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`, `version`, `triggers`, `globs`)
2. Add a `FORMAT.md` (or similarly content-named) companion only if the skill produces a document with a format, or has multi-phase behavior — link it from `SKILL.md`
3. All adapters pick up the new skill automatically via directory glob
