<!--
RULES — read before writing or implementing:
1. FORMAT: Bullets, tables, code, diagrams ONLY — no prose paragraphs
2. REQUIREMENTS: One crisp line each — no verbose descriptions  
3. CHECKLIST: Mark items [x] as you complete them — this is your persistent todo list
4. READING TIME: Optimize for fast human scanning — if it's hard to skim, rewrite it
-->

# Mini-Design: Generic Coding Skill + Guardrails Rename

> Universal coding rules for any project type — backend, CLI, web, bash. Plus rename `guardrails` → `coding-agent-guardrails` to make its scope unambiguous.

**Issue:** upgrade-to-sdlc-nfeaturegrouping-jul26
**Branch:** `upgrade-to-sdlc-nfeaturegrouping-jul26`
**Status:** Pending
**Parent design:** `./plan-sdlc-skill-feature-grouping.md`

**Reference files:**
- Android coding skill: `skills/android-coding/SKILL.md`
- Guardrails skill: `skills/guardrails/SKILL.md` _(renamed to `coding-agent-guardrails/` in Phase 0)_

---

## Problem

- `android-coding` skill is Android-specific — can't use for backend/CLI/web/bash
- No universal coding rules beyond `guardrails` (which is structure-only, no language rules)
- User repeats same guidance across projects (error handling, testing, etc.)
- `guardrails` is an ambiguous name — reads as product/safety guardrails, not "rules the coding agent follows"

## Out of Scope

- Language-specific syntax rules (covered by linters)
- Framework-specific patterns (e.g. React hooks, Django views)
- CI/CD configuration

## Concept

- New `coding` skill with universal rules applicable to any project type
- Layered on `guardrails` (extends, doesn't replace)
- Covers: error handling, testing, API design, dependencies, config management
- Project-type variants auto-detected or configurable

## Requirements

| # | Requirement |
|---|-------------|
| 0 | `guardrails` renamed to `coding-agent-guardrails` — all references updated, no dangling links |
| 1 | Universal rules apply to all project types |
| 2 | Extends `coding-agent-guardrails` — tighter limits where appropriate |
| 3 | Error handling: always catch at boundaries, return typed results |
| 4 | Testing: every non-trivial function has at least one test |
| 5 | API design: consistent naming, versioning, error responses |
| 6 | Dependencies: never change versions in feature work |
| 7 | Config: secrets in env vars, never in code |

---

## Research

### Android-coding structure

- **File:** `skills/android-coding/SKILL.md`
- **Pattern:** numbered sections, code examples for do/don't
- **Layering:** explicitly references guardrails, overrides where tighter

### Guardrails scope

- **File:** `skills/guardrails/SKILL.md`
- **Covers:** file size, code organization, VCS, build warnings
- **Gap:** no language/runtime rules — that's what coding skill fills

---

## Architecture

```
coding-agent-guardrails (base — was: guardrails)
    │
    ├── coding (universal)
    │   ├── error handling
    │   ├── testing discipline
    │   ├── API design
    │   ├── dependency hygiene
    │   └── config/secrets
    │
    └── android-coding (extends coding + coding-agent-guardrails)
        ├── Kotlin/Compose specifics
        ├── ViewModel patterns
        └── Android-only rules
```

---

## Design Details

### Skill Sections

| Section | Rules |
|---------|-------|
| **Error handling** | Catch at boundaries; return `Result<T>` or typed errors; never throw from public APIs |
| **Testing** | Every public function tested; edge cases covered; mocks for external deps |
| **API design** | Consistent naming; version endpoints; structured error responses |
| **Dependencies** | Lock versions; never bump in feature work; document additions |
| **Config** | Secrets in env vars; no hardcoded URLs; feature flags for gating |
| **Logging** | Structured logs; no PII; log levels appropriate to severity |

### Key Decisions

#### Decision 1: Universal vs project-type rules

- **Decision:** Single `coding` skill with universal rules; project-type detection optional
- **Rationale:** Most rules (error handling, testing, etc.) apply universally
- **Where:** `skills/coding/SKILL.md`

#### Decision 2: Layering relationship

- **Decision:** `coding` extends `coding-agent-guardrails`; `android-coding` extends both
- **Rationale:** Clear hierarchy; no duplication; overrides explicit
- **Where:** SKILL.md intro section

```
Skill hierarchy:
  coding-agent-guardrails (structure + VCS + build discipline)
    └── coding (universal runtime rules)
          └── android-coding (Android-specific)
          └── [future] web-coding, cli-coding, etc.
```

#### Decision 4: Guardrails rename scope

- **Decision:** Rename directory + frontmatter `name` + every reference; keep `/guardrails` as a legacy trigger
- **Rationale:** New name states who the rules are for; legacy trigger avoids breaking muscle memory and existing installs
- **Where:** `skills/coding-agent-guardrails/SKILL.md` frontmatter

```yaml
name: coding-agent-guardrails
triggers:
  - "set up guardrails"
  - "/coding-agent-guardrails"
  - "/guardrails"        # legacy alias — keep
```

**Reference sites (from grep):**

| File | References |
|------|-----------|
| `skills/guardrails/SKILL.md` | dir + frontmatter `name` + body |
| `skills/android-coding/SKILL.md` | §1 layering, §2 file-size override, §15 build |
| `skills/android-coding/AGENTS.md` | sibling-skill note (renamed by `02` Phase 0.4) |
| `skills/planning/scaffold.sh` | shell comments (lines 4, 48) |
| `CLAUDE.md`, `AGENTS.md`, `README.md` | skills tables + links |

- Adapters resolve skills by directory glob (`install.sh:38`) → renamed dir is picked up with no adapter edit
- **Stale installs:** `~/.claude/skills/guardrails/` lingers after rename; install script should delete the old directory
- **Known limitation (not fixed in V1):** already-scaffolded Cursor/Gemini projects keep the old name in `.cursor/rules/guardrails.mdc` and their `GEMINI.md` appendix — re-run the installer to refresh

#### Decision 3: Code examples format

- **Decision:** ❌/✅ paired examples for each rule (like android-coding)
- **Rationale:** Unambiguous; agents learn from contrast
- **Where:** Each rule section

---

## Files to Modify

| File | Change |
|------|--------|
| `skills/coding/SKILL.md` | New — universal coding rules |
| `skills/coding/CONTRIBUTING.md` | New — maintainer notes (excluded from installs) |
| `skills/android-coding/SKILL.md` | Add "extends coding" note |

| `CLAUDE.md` | Add coding skill to table |

---

## Implementation Phases

### Phase 0 — Rename guardrails → coding-agent-guardrails

- [x] **0.1** `git mv skills/guardrails skills/coding-agent-guardrails`
- [x] **0.2** Update frontmatter `name:` + add `/coding-agent-guardrails` trigger, keep `/guardrails` alias
- [x] **0.3** Update `skills/android-coding/SKILL.md` (§1, §2, §15) + `skills/android-coding/AGENTS.md` — still named `AGENTS.md` at this point; `02` Phase 0.4 renames it later
- [x] **0.4** Update `skills/planning/scaffold.sh:4,48` guardrails mentions (shell comments only — the emitted text never names the skill)
- [x] **0.5** Update `CLAUDE.md`, `AGENTS.md`, `README.md` skills tables + links
- [x] **0.6** Add stale-install cleanup to `adapters/claude-code/install.sh` (remove old `~/.claude/skills/guardrails/`)

**Verify phase 0:**
- [x] **0.T1** Integration — `grep -rn "skills/guardrails" .` returns zero hits outside `.feature-plans/`
- [x] **0.T2** Integration — `install.sh claude-code`; `~/.claude/skills/coding-agent-guardrails/` exists, old dir gone
- [x] **0.T3** Manual — Every markdown link to the skill resolves (no 404 paths)

---

### Phase 1 — Create coding skill

- [x] **1.1** Create `skills/coding/SKILL.md` with YAML frontmatter
- [x] **1.2** Add error handling section with examples
- [x] **1.3** Add testing discipline section
- [x] **1.4** Add API design section
- [x] **1.5** Add dependency hygiene section
- [x] **1.6** Add config/secrets section
- [x] **1.7** Add logging section

**Verify phase 1:**
- [x] **1.T1** Manual — SKILL.md has ❌/✅ examples for each rule
- [x] **1.T2** Manual — Layering relationship documented

---

### Phase 2 — Create agent guide + update related skills

> No adapter change is needed to *add* a skill — `install.sh:38` globs `"$SKILLS_SRC"/*/`,
> so a new `skills/coding/` directory is picked up automatically.

- [x] **2.1** Create `skills/coding/CONTRIBUTING.md` — maintainer notes only (what belongs in this skill); NOT installed
- [x] **2.2** Update `skills/android-coding/SKILL.md` intro — "extends coding + coding-agent-guardrails"
- [x] **2.3** Update `CLAUDE.md` + `README.md` skills tables with `coding`

**Verify phase 2:**
- [x] **2.T1** Manual — android-coding references both parent skills by final name
- [x] **2.T2** Integration — `./install.sh claude-code`; `~/.claude/skills/coding/SKILL.md` exists (no adapter edit required)

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `skills/guardrails/` → `skills/coding-agent-guardrails/` | 0.1-0.2 | Rename dir + frontmatter + alias trigger |
| `skills/android-coding/SKILL.md` | 0.3, 2.2 | Rename refs + layering note |
| `skills/android-coding/CONTRIBUTING.md` | 0.3 | Rename refs |
| `skills/planning/scaffold.sh` | 0.4 | Rename refs in emitted text |
| `AGENTS.md`, `README.md` | 0.5 | Skills table + links |
| `skills/coding/SKILL.md` | 1.1-1.7 | New universal coding rules |
| `skills/coding/CONTRIBUTING.md` | 2.1 | Maintainer notes (not installed) |
| `adapters/claude-code/install.sh` | 0.6, 2.3 | Stale-install cleanup + add coding skill |
| `CLAUDE.md` | 0.5, 2.4 | Skills table update |

---

## Coding Skill Draft

### Error Handling

```python
# ❌ WRONG — exception escapes boundary
def get_user(id):
    return db.query(User, id)  # throws if not found

# ✅ CORRECT — typed result at boundary
def get_user(id) -> Result[User, NotFoundError]:
    try:
        return Ok(db.query(User, id))
    except DoesNotExist:
        return Err(NotFoundError(f"User {id} not found"))
```

### Testing

```python
# ❌ WRONG — no test for edge case
def divide(a, b):
    return a / b

# ✅ CORRECT — edge cases covered
def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)
```

### Dependencies

```bash
# ❌ WRONG — version bump in feature work
- requests==2.28.0
+ requests==2.31.0  # "while I'm here, might as well update"

# ✅ CORRECT — dedicated dependency update PR
# PR title: "chore(deps): bump requests 2.28.0 → 2.31.0"
# Single-purpose, reviewable, revertable
```

### Config/Secrets

```python
# ❌ WRONG — hardcoded secret
API_KEY = "sk-live-abc123"

# ✅ CORRECT — from environment
API_KEY = os.environ["API_KEY"]
```
