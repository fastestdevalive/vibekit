# android-coding skill — writing guide

This is a **rules** skill, not a workflow skill. It has no scaffolder, no templates, no slash-command behavior beyond injecting its body as context.

## What belongs here

- Cross-project Android/Kotlin/Compose rules that have bitten ≥2 real projects, or that document a concrete failure mode (crash, blank screen, build break).
- Patterns that are stable across DI frameworks (Koin/Hilt), navigation libraries, and target Android versions.

## What does NOT belong here

- Project-specific class names, file paths, or anti-examples by name (e.g. "do not use `HomeViewModel`"). Those belong in each project's own `AGENTS.md`.
- Anything Firebase, FCM topic, color-picker, Crashlytics ID, or vendor-SDK specific.
- Data-model rules tied to a single app's proto schema (e.g. PageLayout, Space, FOCUS_PAGE).
- Release-notes formats, feature-plan conventions, bug-eval references — those are workflow/process, not coding rules.

## Style rules for SKILL.md

- **Hard cap: 200 lines** (per `guardrails`). If you're about to push over, propose a new sibling skill (e.g. `android-compose-advanced`) instead of adding sub-files inside this directory.
- Every rule needs **either a ✅/❌ code example or a one-sentence rationale.** Preferably both. A bare prohibition without a "why" gets ignored.
- Keep code blocks compact — one ✅ + one ❌ per rule, not a full file.
- Use the existing section numbering (1–16). If you add a section, insert it where it logically fits and renumber.
- Prefer "must" / "never" over "should" / "avoid" when the rule is hard. Reserve "prefer" for genuine soft guidance.

## Adding a new rule

1. Confirm the rule has bitten ≥2 projects (or document the failure mode in the rule itself).
2. Confirm it does not name a specific class, file, or vendor SDK.
3. Pick the right section; if none fits, add a new one.
4. Write the rule in 1–3 bullets. Add one code example.
5. Re-run `wc -l SKILL.md` — confirm ≤ 200.

## Updating an existing rule

- Tightening (e.g. lowering the file-size cap): note the previous limit and the reason for the change in the commit message.
- Loosening: justify in the PR description with the concrete pain the old rule caused.

## Versioning

- Bump `version:` in the frontmatter on every substantive change (added/removed/tightened rule). Trivial typo fixes don't need a bump.
