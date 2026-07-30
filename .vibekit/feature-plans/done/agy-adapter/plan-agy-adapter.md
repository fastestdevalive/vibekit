<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# Plan: agy adapter — install vibekit skills into Antigravity's `agy` CLI

> Add a fourth per-tool adapter (`adapters/agy/install.sh`) so `./install.sh agy` installs vibekit skills into `agy`'s workspace customization layout, matching the existing claude-code/cursor/gemini adapters.

**Issue:** agy-adapter
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26` (current)
**Status:** Done — closed 2026-07-30
**PRD:** none — small feature, PRD skipped per SDLC feature-size gate

**Reference files:**
- Dispatcher: `install.sh:1`
- Adapter to model: `adapters/gemini/install.sh:1` (project-scoped, per-skill copy)
- Adapter to model: `adapters/claude-code/install.sh:1` (verbatim-directory copy + skip list)
- Docs: `README.md:79-113`
- Docs: `AGENTS.md` / `CLAUDE.md` — Repo layout section

---

## Problem

- vibekit ships adapters for Claude Code, Cursor, and Gemini CLI only
- A new CLI, `agy` (Google's **Antigravity**, binary at `~/.local/bin/agy`), is installed locally and has its own customization discovery mechanism — no vibekit adapter targets it yet
- Without an adapter, `agy` users must hand-copy `SKILL.md` files into `agy`'s expected layout

## Out of Scope

- Rules-file emission (`AGENTS.md`/`.agents/rules/*.md`) — vibekit's `AGENTS.md`/`CLAUDE.md` at repo root already serve this for any repo-root-context reader (see Q&A below); this plan only adds the **skills** installer
- `skills.json`/`plugins.json` explicit-registration path — workspace hierarchical discovery (the primary path, highest priority) covers vibekit's use case
- Renaming `adapters/` (see Q&A below — answered, not actioned in this plan)
- Cursor/Gemini adapter changes

## Concept

- `agy` (Antigravity) discovers **skills** by walking from CWD up to the repo root looking for `.agents/` (or `.agent/`, `_agents/`, `_agent/`), then reading `<found-dir>/skills/<name>/SKILL.md`
- Skills use the same progressive-disclosure model as Claude Code: only `name` + `description` are loaded by default, full body loads on demand — so vibekit's `SKILL.md` files work **verbatim**, no field translation needed (unlike Cursor's `.mdc` stub or Gemini's slash-command inlining)
- New adapter copies each skill directory into `<target-project>/.agents/skills/<name>/`, same file-skip rules as the claude-code adapter (`evals/`, `CONTRIBUTING.md` excluded)

## Requirements

| # | Requirement |
|---|-------------|
| 1 | `./install.sh agy [skill-name] [target-dir]` installs skill(s) into `<target-dir>/.agents/skills/<name>/` |
| 2 | Default `target-dir` is `$(pwd)`; default `skill-name` is `all` |
| 3 | Non-shipping files (`evals/`, `CONTRIBUTING.md`) are excluded, same as claude-code adapter |
| 4 | A dir with no `SKILL.md` is skipped with a message under `all`, never aborts the run (same convention as cursor/gemini adapters) |
| 5 | README + repo-layout docs updated to list the new adapter |

---

## Research

### How `agy` discovers customizations

- **Binary:** `/home/gb/.local/bin/agy` — Google's Antigravity CLI (Gemini-family; internal codename strings reference `codeium`/`cortex`/`cascade`/CloudCode)
- **Embedded skill doc:** `agy-customizations` (bundled skill inside the binary, extracted via `strings`) — canonical source for the table below

| Customization type | Config file/folder | Notes |
|---|---|---|
| Rules | `GEMINI.md`, `AGENTS.md`, `.agents/rules/*.md` | Hierarchical — walks up from edited file to repo root |
| **Skills** | `skills/<name>/SKILL.md` | Relative to the discovered `.agents/` (or `.agent/`, `_agents/`, `_agent/`) dir |
| Plugins | `plugins/<name>/plugin.json` | Bundles skills+rules+MCP — out of scope here |
| Hooks | `hooks.json` | Out of scope |
| MCP servers | `mcp_config.json` | Out of scope |

- **Discovery locations, in priority order (highest first):**
  1. Workspace project — hierarchical walk from CWD to repo root (`.agents/`, `.agent/`, `_agents/`, `_agent/`)
  2. Declared configs — `skills.json`/`plugins.json` in the workspace
  3. Global — `~/.gemini/config/`
  4. Built-in — bundled with the app
  5. Global declared configs
- **Progressive disclosure:** skills are NOT loaded into context by default — only `name`+`description` from frontmatter are injected; full `SKILL.md` body loads only when the agent/user activates it — **identical model to Claude Code**, so no content rewriting is needed, only file placement
- **Risk:** LOW — placement-only adapter, no format translation, mirrors the already-shipped claude-code adapter's copy logic

### Adapter pattern comparison

- **File:** `adapters/claude-code/install.sh:1`
- User-scoped (`~/.claude/skills/`), does stale-skill cleanup, copies whole dir minus skip-list — closest structural match to what `agy` needs (verbatim `SKILL.md`, no per-tool field translation)
- **File:** `adapters/gemini/install.sh:1`
- Project-scoped (`$TARGET/...`), `skill-name` then `target-dir` positional args — matches the **argument shape** agy needs (project-local, not `$HOME`)
- **Decision:** agy adapter takes the claude-code adapter's **copy body** (whole-dir copy, skip evals/CONTRIBUTING.md) but the gemini adapter's **argument shape** (project-scoped, `[skill-name] [target-dir]`) — no stale-cleanup pass, since `agy` installs are project-local and don't need a persistent stale-skill registry like the global `~/.claude/skills/` does

## Root Cause

- N/A — this is new capability, not a bug fix

---

## Modules & Interfaces

| Module | Change | Responsibility | Public interface | Owns |
|--------|--------|---------------|-------------------|------|
| `adapters/agy/install.sh` | **New** | Copy skill dir(s) into `.agents/skills/<name>/` under a target project | `./install.sh [skill-name] [target-project-dir]` | nothing (stateless script) |
| `install.sh` (top-level dispatcher) | **Modified** | Usage string only — lists `agy` as a valid tool name | unchanged — dispatch logic is generic (`adapters/$TOOL/install.sh`) | — |
| `README.md` | **Modified** | Document the new adapter | — | — |

- No **dispatch-logic** change needed in the top-level `install.sh:1` — it already resolves `adapters/<tool>/install.sh` generically; "Modified" above refers only to the usage/help string (Phase 1.2), not the routing itself

---

## Architecture Diagram

- Pure addition of a sibling adapter script — no existing module's control flow changes; one line saying so, no diagram needed.

```
install.sh agy [skill] [target]
  → adapters/agy/install.sh [skill] [target]
      → copies skills/<name>/* → <target>/.agents/skills/<name>/
```

---

## Design Details

### System Boundaries

- Single layer (filesystem copy script) — System Boundaries table not required per `FORMAT.md`

### Critical User Journeys (CUJs)

#### CUJ 1 — Install all skills into an agy-managed project

```
User runs `./install.sh agy all /path/to/project`
  → adapter creates /path/to/project/.agents/skills/ if missing
  → for each skills/<name>/ with a SKILL.md: copies dir (minus evals/, CONTRIBUTING.md)
    → /path/to/project/.agents/skills/<name>/
  → prints "wrote  <dest>/<file>" per file, "Done." summary at the end
```

- **Error path:** `skill-name` given explicitly but has no `SKILL.md` → `Error: no SKILL.md for <name>` to stderr, exit 1 (matches gemini/cursor adapter behavior)
- **Edge case:** `all` mode encountering a companion-only dir (no `SKILL.md`) → skip with a message, continue the loop (matches gemini/cursor `skip <name> (no SKILL.md)` convention)

#### CUJ 2 — Install a single skill

```
User runs `./install.sh agy planning /path/to/project`
  → adapter validates skills/planning/SKILL.md exists
  → copies skills/planning/* (minus skip-list) → /path/to/project/.agents/skills/planning/
```

### Data Model

- N/A — no persisted data, filesystem copy only

### API Contracts

- N/A — no network/RPC boundary; CLI argument contract only:

```
adapters/agy/install.sh [skill-name] [target-project-dir]
  skill-name:        name under skills/, or "all" (default: all)
  target-project-dir: default $(pwd)
  exit 0  → success
  exit 1  → named skill has no SKILL.md
```

### Key Decisions

#### Decision 1: Target `.agents/skills/<name>/`, not `.agent/`/`_agents/`/`_agent/` — *no snippet needed*

- **Decision:** always write to `.agents/skills/<name>/` (the canonical/first-listed form)
- **Rationale:** `agy` accepts 4 alternate root dir names for its workspace layer, but `.agents/` is the canonical one documented first in its own customization guide; a fixed target avoids ambiguity about which alt-name to prefer, and a project can rename/symlink locally if it already uses an alt form
- **Where:** `adapters/agy/install.sh` — `AGENTS_SKILLS_DIR="$TARGET/.agents/skills"`

#### Decision 2: Copy whole directory verbatim, no frontmatter translation — *no snippet needed*

- **Decision:** reuse the claude-code adapter's copy-minus-skiplist file-copy loop; do not inline into a single context file (unlike the gemini adapter) and do not strip to just `SKILL.md` (unlike the cursor `.mdc` stub). **Existence check is the gemini/cursor pattern, not claude-code's**: validate `$SKILLS_SRC/$name/SKILL.md` (file) exists, not just the directory — a dir without `SKILL.md` is a companion-only/probe dir, not a skill, so it must fail the same way gemini/cursor's `[[ ! -f "$src" ]]` check does
- **Rationale:** agy's skill loader reads `SKILL.md` frontmatter (`name`, `description`) directly and supports companion files via the same directory, same as Claude Code's `~/.claude/skills/<name>/` — no format gap to bridge for the copy step. But claude-code's dir-exists check would wrongly treat a companion-only dir as a valid single-skill target; matching gemini/cursor's file-exists check keeps `agy <name>` and `agy all` consistent about what counts as "a skill"
- **Where:** `adapters/agy/install.sh` — `install_one()`: copy loop modeled on `adapters/claude-code/install.sh:29-64` minus the stale-cleanup block; existence check modeled on `adapters/gemini/install.sh:26-30` (`[[ ! -f "$src" ]] && echo "Error: no SKILL.md for $name" >&2 && return 1`)

#### Decision 3: Project-scoped args, not user-scoped — *no snippet needed*

- **Decision:** `[skill-name] [target-project-dir]`, defaulting `target-project-dir` to `$(pwd)`, matching cursor/gemini adapters — not a fixed `$HOME`-relative dir like claude-code's `CLAUDE_SKILLS_DIR`
- **Rationale:** agy's workspace discovery is per-project (`.agents/` walked from CWD to repo root), so there is no single global install location analogous to `~/.claude/skills/`
- **Where:** `adapters/agy/install.sh` — arg parsing block

---

## Files to Modify

| File | Change |
|------|--------|
| `adapters/agy/install.sh` | New adapter script |
| `README.md` | Add agy row to Skills-install table, repo-layout tree, Quick start example |
| `CLAUDE.md` | `## Repo layout` tree (`CLAUDE.md:46-49`) lists `claude-code/install.sh`, `cursor/install.sh`, `gemini/install.sh` — add `agy/install.sh` line |
| `AGENTS.md` | Check for the same repo-layout tree; update in parallel with `CLAUDE.md` if present |

## Risks / Open Questions

| # | Question | Notes |
|---|----------|-------|
| 1 | **Should the adapter also emit `.agents/rules/*.md`?** | Out of scope for this plan — vibekit's root `AGENTS.md`/`CLAUDE.md` already satisfy agy's hierarchical rules discovery for anyone running agy inside the vibekit repo itself; scaffolded target projects get `AGENTS.md`/`CLAUDE.md` from `scaffold.sh` already. Revisit only if a real gap surfaces. |
| 2 | **`.agents/` vs `.agent/`/`_agents/`/`_agent/` — could a target project prefer an alt name?** | Decision 1 above: always emit the canonical `.agents/`; not configurable in V1 |

---

## Q&A for the user (answered inline, not part of the checklist)

**Q: What is the `adapters/` directory for? Is it for installations?**
A: Yes — one subdirectory per supported CLI tool (`claude-code/`, `cursor/`, `gemini/`, and now `agy/`), each holding a thin `install.sh` that copies/translates `skills/<name>/SKILL.md` into that tool's native format. The top-level `install.sh:1` dispatches to `adapters/<tool>/install.sh`. See `README.md:79-113`.

**Q: Can we rename `adapters/` to something else?**
A: Yes, mechanically — nothing hardcodes the string `adapters` outside `install.sh:1` (`ADAPTER="$SCRIPT_DIR/adapters/$TOOL/install.sh"`) and the docs (`README.md`, `CLAUDE.md`/`AGENTS.md` repo-layout trees). A rename is a 1-line dispatcher change + doc updates + `git mv`. **Not done in this plan** — no rename was requested, only asked about; flagging back to you rather than silently renaming a directory referenced by 4 install scripts and 3 doc files.

---

## Implementation Phases

- Each phase ends with a **verification block** — the phase is not complete until those tests pass
- Device verification: N/A — this is a shell-script + docs change, no UI

---

### Phase 1 — Adapter script

- [x] **1.1** Create `adapters/agy/install.sh`:
  - Header comment: purpose + usage (`[skill-name] [target-project-dir]`)
  - `SCRIPT_DIR` / `REPO_ROOT` / `SKILLS_SRC` resolution, same pattern as `adapters/claude-code/install.sh:9-11`
  - `SKILL="${1:-all}"`, `TARGET="${2:-$(pwd)}"`, `AGENTS_SKILLS_DIR="$TARGET/.agents/skills"`
  - `install_one()`: validate `$SKILLS_SRC/$name/SKILL.md` exists as a **file** (not just the dir) — `[[ ! -f "$src/SKILL.md" ]]` → `echo "Error: no SKILL.md for $name" >&2; return 1` (mirror `adapters/gemini/install.sh:26-30`, NOT claude-code's dir-only check); `mkdir -p "$AGENTS_SKILLS_DIR/$name"`; loop-copy files from `$SKILLS_SRC/$name/*` skipping `evals` and `CONTRIBUTING.md` (mirror `adapters/claude-code/install.sh:53-61`); echo `wrote  <dest>/<file>` per file
  - `all` mode: loop `skills/*/`, skip dirs without `SKILL.md` with `skip   <name> (no SKILL.md)` (mirror `adapters/gemini/install.sh:57-65`)
  - Trailing summary: `echo; echo "Done. Installed into: $AGENTS_SKILLS_DIR"`
  - `chmod +x adapters/agy/install.sh`
- [x] **1.2** Update `install.sh` usage string (`install.sh:14`) to include `agy` in the tool list

**Verify phase 1:**
- [x] **1.T1** Manual — `./install.sh agy all /tmp/agy-adapter-test` — every `skills/*/SKILL.md` dir lands at `/tmp/agy-adapter-test/.agents/skills/<name>/SKILL.md`; `evals/` and `CONTRIBUTING.md` absent from `coding/` and `android-coding/` output dirs — PASS
- [x] **1.T2** Manual — `./install.sh agy planning /tmp/agy-adapter-test2` — only `.agents/skills/planning/` created, with `SKILL.md`, `FORMAT.md`, `SECTIONS.md`, `_template_arch.md`, `_template_plan.md`, `scaffold.sh` — PASS
- [x] **1.T3** Manual — `./install.sh agy nonexistent-skill /tmp/agy-adapter-test3` — prints `Error: no SKILL.md for nonexistent-skill` to stderr, exits non-zero — PASS
- [x] **1.T3b** Code read confirms the check is `[[ ! -f "$src/SKILL.md" ]]` (`adapters/agy/install.sh:28`) — file-exists, not dir-exists — PASS
- [x] **1.T4** Manual — re-ran `./install.sh agy all /tmp/agy-adapter-test` a second time — idempotent, exit 0, files overwritten cleanly — PASS
- [x] **1.T5** Lint — `bash -n adapters/agy/install.sh` passes — PASS

---

### Phase 2 — Docs

- [x] **2.1** `README.md` — add `agy` row to the "native location / what gets installed" table (`README.md:105-111`)
- [x] **2.2** `README.md` — add `adapters/agy/install.sh` line to the repo-layout tree (`README.md:79-82`)
- [x] **2.3** `README.md` — add a Quick-start example line, mirroring the gemini one (`README.md:126-127`)
- [x] **2.4** `CLAUDE.md:46-49` and `AGENTS.md` (same tree, verify line numbers match) — add `agy/install.sh     ← → .agents/skills/<name>/` under the `adapters/` block, alongside the existing `claude-code/`, `cursor/`, `gemini/` lines

**Verify phase 2:**
- [x] **2.T1** Manual — `grep -n agy README.md` shows all 3 additions — PASS
- [x] **2.T2** Manual — re-read the updated README table/tree for formatting consistency with existing rows — PASS

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `adapters/agy/install.sh` | 1.1 | New adapter script |
| `install.sh` | 1.2 | Usage string includes `agy` |
| `README.md` | 2.1–2.3 | New adapter documented |
| `AGENTS.md` / `CLAUDE.md` | 2.4 | Repo-layout tree parity, if applicable |
