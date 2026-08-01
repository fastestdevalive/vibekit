# vibekit

> Personal toolkit of agentic software development skills — usable across Claude Code, Cursor, agy (Antigravity), and OpenCode.

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

## Usage

Once installed (see [Getting started](#getting-started)), skills trigger on the phrases/slash-commands in each `SKILL.md`'s frontmatter. `/sdlc` is the main entry point — it drives `prd` → `planning` through review/implement/verify as one chain, so most invocations name a **feature slug** and, for a fresh feature, a description after a colon. Five of the most common flows:

1. **Large feature — chain PRD + Plan, stop for review before any code is touched**
   ```
   /sdlc prd-plan auth-flow: Add OAuth login with Google and GitHub, replacing email/password
   ```
   Writes `prd-auth-flow.md`, then `plan-auth-flow.md`; stops after `plan` (`AWAITING: plan`) instead of auto-continuing into implementation.

2. **Small change — single-phase chain, skip the PRD**
   ```
   /sdlc plan copy-clipboard-button: Add a "copy to clipboard" button to the settings screen
   ```
   Runs just the `plan` phase and stops — no PRD, no implementation started yet.

3. **Full orchestrated SDLC, no chain given — PRD → Plan → Review → Implement → Verify → Review, end to end**
   ```
   /sdlc multi-account-support: Add multi-account switching to the app
   ```
   Runs the entire default chain with resumable state — re-running `/sdlc multi-account-support` later (e.g. a fresh session) picks up exactly where it left off, never redoing a completed phase.

4. **Chain multiple remaining phases together, skipping ones already done**
   ```
   /sdlc implement-verify auth-flow
   ```
   Plan for `auth-flow` is already written and reviewed — this runs `implement` then `verify` in one invocation and stops again for the next review, without re-running `prd`/`plan`. (If the feature is still paused awaiting a prior phase, the agent stops and asks before discarding that pause rather than silently jumping ahead — use `/sdlc continue` first in that case.)

5. **Advance exactly one phase past a pause, or check where things stand**
   ```
   /sdlc continue
   /sdlc status
   ```
   `continue` advances the currently-awaiting feature by one phase and re-pauses; `status` reports feature, mode, `AWAITING: <phase> — <artifact>`, and the next unchecked checklist item, without changing anything.

---

## Getting started

### Install

Every installer installs **all skills** — there's no per-skill option — so you just pick a tool. Quickest is the one-line curl install (below); a manual clone works too if you want to inspect the repo or pin a commit first.

**Quickest — one-line install (Claude Code, global):**

```bash
curl -fsSL https://raw.githubusercontent.com/fastestdevalive/vibekit/main/scripts/get.sh | bash -s -- claude-code
```

This clones vibekit into `~/.vibekit` and installs every skill into `~/.claude/skills/`. Works for any tool the dispatcher supports:

```bash
curl -fsSL https://raw.githubusercontent.com/fastestdevalive/vibekit/main/scripts/get.sh | bash -s -- opencode    # global, no path needed
curl -fsSL https://raw.githubusercontent.com/fastestdevalive/vibekit/main/scripts/get.sh | bash -s -- agy         # project-scoped — run from inside your project, or add --project=/path
curl -fsSL https://raw.githubusercontent.com/fastestdevalive/vibekit/main/scripts/get.sh | bash -s -- cursor      # project-scoped — run from inside your project, or add --project=/path
```

Whether that installs **globally** (every project on your machine, no per-project step) or **per-project** depends on what the tool itself supports:

| Tool | Default scope | Why |
|------|----------------|-----|
| **Claude Code** | Global — `~/.claude/skills/` | Has a real global skills dir; no per-project concept at all |
| **OpenCode** | Global — `~/.config/opencode/skills/` | Confirmed by [official docs](https://opencode.ai/docs/skills.md): a native Skills system (same progressive-disclosure model as Claude Code) reads a global `~/.config/opencode/skills/` dir in every project, alongside a project-local `.opencode/skills/` |
| **agy (Antigravity)** | Project — `.agents/skills/` in the target repo | Antigravity's own docs disagree with each other on the global path; project scope is the only one reliably documented. `--global` opts into an empirically-found (unofficial) path if you want to try it |
| **Cursor** | Project — `.cursor/rules/` in the target repo | Cursor's only global option is **Settings → Customize → Rules**, a single text box in the app UI — there's no file/folder a script can write to. `--global` explains this and exits instead of guessing |

Only pass `--project=<dir>` when you deliberately want a project-scoped install instead of the default for that tool (or you're not standing inside the target project already, since the fallback is the current directory).

**Manual — clone + run the installer directly:**

```bash
git clone https://github.com/fastestdevalive/vibekit.git
cd vibekit

# Global installs — no path needed
./install.sh claude-code
./install.sh opencode

# Project-scoped installs — defaults to the current directory
cd /path/to/your/project && /path/to/vibekit/install.sh cursor
cd /path/to/your/project && /path/to/vibekit/install.sh agy
# ...or stay put and point at the project explicitly:
./install.sh cursor --project=/path/to/your/project
./install.sh agy --project=/path/to/your/project
```

Then bootstrap a project:

```bash
# Creates .vibekit/feature-plans/{pending,wip,done}/, PRD + plan templates, AGENTS.md, CLAUDE.md
./skills/planning/scaffold.sh /path/to/your/project
```

### Updating

- **Installed via the curl one-liner** — re-run the exact same command. It `git pull`s `~/.vibekit` to the latest `main` and re-runs the installer:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/fastestdevalive/vibekit/main/scripts/get.sh | bash -s -- claude-code
  ```
- **Installed via manual clone** — `git pull` inside your clone, then re-run `./install.sh <tool>`:
  ```bash
  cd vibekit && git pull && ./install.sh claude-code
  ```

Every adapter overwrites each shipped skill's content on re-run, so edits upstream (a changed `SKILL.md`, a new companion file) always reach an existing install. The one thing re-running does **not** do everywhere is clean up a skill that vibekit retires outright (rare — skills get edited far more often than removed): Claude Code, agy, and OpenCode sync away stale files *within* a skill's own folder, and Claude Code additionally has a short hardcoded list for skills renamed/removed at the top level. None of the adapters auto-remove a skill's leftover top-level file/folder if it's fully retired upstream — delete it by hand in that rare case.

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
├── AGENTS.md                           ← agent guide (OpenCode, Codex, etc.)
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
│   ├── agy/install.sh                  ← → .agents/skills/<name>/
│   └── opencode/install.sh             ← → ~/.config/opencode/skills/<name>/
├── scripts/
│   └── get.sh                          ← curl-installable bootstrap (clone/update ~/.vibekit + install)
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
  - ".vibekit/feature-plans/**"
---
```

Each adapter cherry-picks the fields its target tool understands:

| Tool | Native location | What gets installed |
|------|-----------------|---------------------|
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` (global) | `SKILL.md` + companion files copied verbatim, each loaded on demand |
| **Cursor** | `<project>/.cursor/rules/<name>.mdc` (project-scoped — no scriptable global exists) | `SKILL.md` **+ every linked companion inlined** into the single `.mdc` (Cursor has no companion-file mechanism) |
| **agy (Antigravity)** | `<project>/.agents/skills/<name>/SKILL.md` (project-scoped by default) | whole skill dir copied verbatim, same progressive-disclosure model as Claude Code |
| **OpenCode** | `~/.config/opencode/skills/<name>/SKILL.md` (global by default), or `<project>/.opencode/skills/<name>/SKILL.md` with `--project=<dir>` | whole skill dir copied verbatim — OpenCode's native Skills system uses the same progressive-disclosure model as Claude Code |

Both `AGENTS.md` and `CLAUDE.md` live at the repo root so Claude Code and OpenCode automatically load project context when working inside this repo or a scaffolded project.

---

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

---

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

---

## License

MIT
