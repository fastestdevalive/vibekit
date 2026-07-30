# vibekit

> Personal toolkit of agentic software development skills — usable across Claude Code, Cursor, and Gemini CLI.

Skills are written once as plain Markdown and adapted to each tool's native skill/rule format via thin per-tool adapters.

---

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

---

## Skills

| Skill | What it does | Status |
|-------|-------------|--------|
| `prd` | PRD template + writing guide — user behavior, options, decisions, screen layouts | ✅ v0.1 |
| `planning` | Bullet-point technical plan + phased checklists with per-phase test verification | ✅ v0.2 |
| `coding-agent-guardrails` | File size limits, code structure, VCS discipline, build behavior | ✅ v0.1 |
| `coding` | Universal coding rules — error handling, testing, API design, dependencies, config/secrets, logging | ✅ v0.1 |
| `android-coding` | Android/Kotlin/Compose rules, extends `coding` + `coding-agent-guardrails` | ✅ v0.1 |
| `sdlc` | Orchestrates PRD → Plan → Review → Implement → Verify → Review, pluggable reviewer + resumable state | ✅ v0.1 |
| `report` | One-shot investigation → findings document — no state, no checklist, no phases | ✅ v0.1 |
| `code-review` | Agent-friendly review checklists + PR templates | 🔜 planned |
| `debugging` | Structured bug investigation + RCA template | 🔜 planned |
| `architecture` | ADR template (bullet-point style) | 🔜 planned |

---

## Repo layout

```
vibekit/
├── AGENTS.md                           ← agent guide (Gemini, Codex, etc.)
├── CLAUDE.md                           ← same, for Claude Code
├── README.md
├── LICENSE
├── skills/
│   ├── prd/
│   │   ├── SKILL.md                              ← source of truth + frontmatter
│   │   ├── FORMAT.md                             ← PRD writing guide
│   │   └── _prd_sample_format.md                 ← PRD template
│   ├── planning/
│   │   ├── SKILL.md                              ← source of truth + frontmatter
│   │   ├── FORMAT.md                             ← writing rules
│   │   ├── SECTIONS.md                           ← per-section templates
│   │   ├── _template_arch.md                     ← arch template — rare, system-level decomposition
│   │   ├── _template_plan.md                     ← plan template — the default
│   │   └── scaffold.sh                           ← project bootstrapper
│   ├── coding-agent-guardrails/
│   │   └── SKILL.md                              ← universal code quality rules
│   ├── coding/
│   │   ├── SKILL.md                              ← universal coding rules
│   │   └── CONTRIBUTING.md                       ← maintainer notes (not installed)
│   ├── android-coding/
│   │   ├── SKILL.md                              ← Android/Kotlin/Compose rules
│   │   └── CONTRIBUTING.md                       ← maintainer notes (not installed)
│   ├── sdlc/
│   │   ├── SKILL.md                              ← orchestration + config + decomposition
│   │   ├── PHASES.md                             ← per-phase agent behavior
│   │   ├── GRAMMAR.md                            ← invocation grammar + gate/pause lifecycle
│   │   ├── EXAMPLES.md                           ← 9 worked usage examples
│   │   └── evals/                                ← eval cases (not installed)
│   └── report/
│       ├── SKILL.md                              ← source of truth + frontmatter
│       └── _template_report.md                   ← findings-doc template
├── adapters/
│   ├── claude-code/install.sh          ← → ~/.claude/skills/<name>/
│   ├── cursor/install.sh               ← → .cursor/rules/<name>.mdc
│   ├── gemini/install.sh               ← → GEMINI.md + .gemini/commands/<name>.md
│   └── agy/install.sh                  ← → .agents/skills/<name>/
└── install.sh                          ← top-level dispatcher
```

---

## How skills work across tools

Each skill ships a `SKILL.md` with YAML frontmatter:

```yaml
---
name: planning
description: Structured technical plan with bullet-point format and phased checklists
version: 0.2.0
triggers:
  - "plan a feature"
  - "/plan"
globs:
  - ".feature-plans/**"
---
```

Each adapter cherry-picks the fields its target tool understands:

| Tool | Native location | What gets installed |
|------|-----------------|---------------------|
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` | `SKILL.md` copied verbatim |
| **Cursor** | `.cursor/rules/<name>.mdc` | `SKILL.md` verbatim |
| **Gemini CLI** | `GEMINI.md` (context) + `.gemini/commands/<name>.md` (slash cmd) | body inlined in both |
| **agy (Antigravity)** | `.agents/skills/<name>/SKILL.md` | whole skill dir copied verbatim, same progressive-disclosure model as Claude Code |

Both `AGENTS.md` and `CLAUDE.md` live at the repo root so Claude Code and Gemini CLI automatically load project context when working inside this repo or a scaffolded project.

---

## Quick start

```bash
git clone https://github.com/fastestdevalive/vibekit.git
cd vibekit

# Install all skills into Claude Code (~/.claude/skills/)
./install.sh claude-code

# Install into a Gemini CLI project (GEMINI.md + .gemini/commands/)
./install.sh gemini all /path/to/your/project

# Install into an agy (Antigravity) project (.agents/skills/)
./install.sh agy all /path/to/your/project

# Per-skill install
./adapters/claude-code/install.sh planning
```

Then bootstrap a project:

```bash
# Creates .feature-plans/{pending,wip,done}/, PRD + plan templates, AGENTS.md, CLAUDE.md
./skills/planning/scaffold.sh /path/to/your/project
```

---

## Feature-plan directory layout

```
.feature-plans/<state>/<feature>/     ← state: pending | wip | done
  prd-<feature>.md                    ← master PRD (optional)
  arch-<feature>.md                   ← master arch (rare — only if system-level decomposition is needed)
  plan-<feature>.md                   ← master plan
  NN-<subfeature>/
    plan-<NN>-<feature>-<subfeature>.md
    screenshots/                      ← transient by default, gitignored
```

- Simple features skip the sub-feature dirs — just `plan-<feature>.md` at the feature root
- Backward compat: flat `pending/<slug>.md` files still work

---

## Reports directory layout

```
.reports/
  YYYY-MM-DD-<slug>.md                  ← flat report, no screenshots
  YYYY-MM-DD-<slug>/
    report.md
    screenshots/                        ← gitignored unless permanent
```

- Not under `.feature-plans/` — a report is a dated snapshot, not a plan with a lifecycle
- Never edited in place — superseding a report means writing a new dated one

---

## License

MIT
