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
| **Guardrails** | Applied continuously on every file touched | `guardrails` |

For small changes (bug fixes, single-screen tweaks, refactors): skip the PRD, write a technical plan or go straight to implementation.

---

## Skills

| Skill | What it does | Status |
|-------|-------------|--------|
| `prd` | PRD template + writing guide — user behavior, options, decisions, screen layouts | ✅ v0.1 |
| `planning` | Bullet-point technical plan + phased checklists with per-phase test verification | ✅ v0.2 |
| `guardrails` | File size limits, code structure, VCS discipline, build behavior | ✅ v0.1 |
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
│   │   ├── skill.md                    ← source of truth + frontmatter
│   │   ├── AGENTS.md                   ← PRD writing guide
│   │   └── _prd_sample_format.md       ← PRD template
│   ├── planning/
│   │   ├── skill.md                    ← source of truth + frontmatter
│   │   ├── AGENTS.md                   ← technical plan writing guide
│   │   ├── _plan_sample_format.md      ← technical plan template
│   │   └── scaffold.sh                 ← project bootstrapper
│   └── guardrails/
│       └── skill.md                    ← universal code quality rules
├── adapters/
│   ├── claude-code/install.sh          ← → ~/.claude/skills/<name>/
│   ├── cursor/install.sh               ← → .cursor/rules/<name>.mdc
│   └── gemini/install.sh               ← → GEMINI.md + .gemini/commands/<name>.md
└── install.sh                          ← top-level dispatcher
```

---

## How skills work across tools

Each skill ships a `skill.md` with YAML frontmatter:

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
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` | `skill.md` renamed to `SKILL.md` |
| **Cursor** | `.cursor/rules/<name>.mdc` | `skill.md` verbatim |
| **Gemini CLI** | `GEMINI.md` (context) + `.gemini/commands/<name>.md` (slash cmd) | body inlined in both |

Both `AGENTS.md` and `CLAUDE.md` live at the repo root so Claude Code and Gemini CLI automatically load project context when working inside this repo or a scaffolded project.

---

## Quick start

```bash
git clone https://github.com/fastestdevalive/vibekit.git
cd vibekit

# Install all skills into Claude Code (~/.claude/skills/)
./install.sh claude-code

# Install into a Gemini CLI project (GEMINI.md + .gemini/commands/)
./install.sh gemini /path/to/your/project

# Per-skill install
./adapters/claude-code/install.sh planning
```

Then bootstrap a project:

```bash
# Creates .feature-plans/{pending,wip,done}/, PRD + plan templates, AGENTS.md, CLAUDE.md
./skills/planning/scaffold.sh /path/to/your/project
```

---

## License

MIT
