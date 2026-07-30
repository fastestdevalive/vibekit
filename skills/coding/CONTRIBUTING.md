# coding skill — maintainer notes

> Excluded from adapter installs. Not loaded by agents — this file is for humans editing the skill.

## What belongs here

- Rules that apply to **any** project type — backend, CLI, web, bash
- Cross-cutting concerns: error handling, testing, API design, dependency hygiene, config/secrets, logging

## What does NOT belong here

- Language-specific syntax rules — those belong to a linter, not this skill
- Framework-specific patterns (React hooks, Django views, etc.) — belongs in a project-type skill
- Anything already covered by `coding-agent-guardrails` (file size, VCS, build warnings) — don't duplicate, reference it
- Project-specific class names, file paths, vendor SDKs

## Adding a new rule

1. Confirm the rule is universal — not tied to one language or framework
2. Confirm it isn't already covered by `coding-agent-guardrails`
3. Add a `❌`/`✅` example — a bare prohibition without a "why" gets ignored
4. Bump `version:` in frontmatter on any substantive change

## Relationship to project-type skills

- `android-coding` (and future `web-coding`, `cli-coding`) extend this skill
- Tighter, language-specific rules win in the project-type skill; this skill stays generic
