# vibekit

> Personal toolkit of agentic software development skills — usable across Claude Code, Cursor, and Gemini CLI.

Skills are written once as plain Markdown and adapted to each tool's native skill/rule format via thin per-tool adapters.

---

## What's in here

| Skill | What it does | Status |
|-------|--------------|--------|
| `planning` | Bullet-point feature plan template + agent writing guide + `.feature-plans/` scaffolder | ✅ v0.1 |
| `code-review` | Agent-friendly review checklists + PR templates | 🔜 planned |
| `debugging` | Structured bug investigation + RCA template | 🔜 planned |
| `architecture` | ADR template (bullet-point style) | 🔜 planned |
| `bootstrap` | One-command project bootstrap (CLAUDE.md, AGENTS.md, .feature-plans/) | 🔜 planned |

---

## Repo layout

```
vibekit/
├── README.md
├── LICENSE
├── skills/
│   └── planning/
│       ├── skill.md                  ← source of truth + frontmatter
│       ├── _plan_sample_format.md    ← the template
│       ├── AGENTS.md                 ← writing guide
│       └── scaffold.sh               ← creates .feature-plans/{pending,wip,done}/
├── adapters/
│   ├── claude-code/install.sh        ← → ~/.claude/skills/<name>/
│   ├── cursor/install.sh             ← → .cursor/rules/<name>.mdc
│   └── gemini/install.sh             ← → GEMINI.md / .gemini/commands/
└── install.sh                        ← top-level dispatcher (detects tool)
```

---

## How skills work across tools

Each skill ships a `skill.md` with a YAML frontmatter superset:

```yaml
---
name: planning
description: Structured feature planning with bullet-point format and phased checklists
version: 0.1.0
triggers:
  - "plan a feature"
  - "/plan"
globs:
  - ".feature-plans/**"
---
```

Each adapter cherry-picks the fields its target tool understands:

| Tool | Native location | Fields used |
|------|-----------------|-------------|
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` | `name`, `description` |
| **Cursor** | `.cursor/rules/<name>.mdc` | `description`, `globs` |
| **Gemini CLI** | `GEMINI.md` / `.gemini/commands/*.toml` | body inlined |

---

## Quick start

```bash
git clone https://github.com/fastestdevalive/vibekit.git
cd vibekit

# Install all skills into Claude Code (~/.claude/skills/)
./install.sh claude-code

# Or per-tool / per-skill
./adapters/claude-code/install.sh planning
```

Then in your project:

```bash
# Scaffold the .feature-plans/ structure for the planning skill
./skills/planning/scaffold.sh /path/to/your/project
```

---

## License

MIT
