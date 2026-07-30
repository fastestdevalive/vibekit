---
name: coding
description: Universal coding rules for any project type — error handling, testing, API design, dependency hygiene, config/secrets, logging. Extends `coding-agent-guardrails`.
version: 0.1.0
triggers:
  - "coding rules"
  - "/coding"
globs:
  - "**/*"
---

# Coding skill

Universal rules for any project type — backend, CLI, web, bash.
Apply these on every file you touch.

## Layering

```
coding-agent-guardrails (base — structure + VCS + build discipline)
    │
    ├── coding (this skill — universal runtime rules)
    │   ├── error handling
    │   ├── testing discipline
    │   ├── API design
    │   ├── dependency hygiene
    │   ├── config/secrets
    │   └── logging
    │
    └── android-coding (extends coding + coding-agent-guardrails)
        ├── Kotlin/Compose specifics
        └── Android-only rules
```

- **Read the `coding-agent-guardrails` skill before applying anything here** — it governs every file you touch (file size, code organization, VCS discipline, build behavior) and is always in force.
- This skill **extends** it; it never replaces it. Where both speak, the tighter rule wins for the matching file type.
- Where a project-type-specific skill (`android-coding`, future `web-coding`, `cli-coding`) specifies a tighter rule, that skill wins for its file types.

## 1. Error handling — catch at boundaries

- Catch errors at the boundary (API handler, CLI entrypoint, background job) — never let them escape uncaught
- Return typed results (`Result<T>`, `Either<Error, T>`, or a language-idiomatic equivalent) — never throw from a public API
- Every error the caller must handle is named, not generic

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

## 2. Testing — every non-trivial function has one

- Every public function with non-trivial logic gets at least one test
- Cover edge cases explicitly — empty input, zero, negative, boundary values
- Mock external dependencies (network, filesystem, clock) — tests must be deterministic

```python
# ❌ WRONG — no test for the edge case
def divide(a, b):
    return a / b

# ✅ CORRECT — edge case covered
def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)
```

## 3. API design — consistent, versioned, typed errors

- Consistent naming across endpoints/methods — same verb/noun conventions throughout
- Version endpoints (`/api/v1/...`) before a breaking change, not after
- Structured error responses — a machine-readable code plus a human message, never a bare string

```json
// ❌ WRONG
{ "error": "something went wrong" }

// ✅ CORRECT
{ "error": { "code": "USER_NOT_FOUND", "message": "User 42 not found" } }
```

## 4. Dependencies — never change versions in feature work

- Never bump a dependency version as a side effect of feature work
- Version bumps get their own dedicated, single-purpose change

```bash
# ❌ WRONG — version bump bundled into feature work
- requests==2.28.0
+ requests==2.31.0  # "while I'm here, might as well update"

# ✅ CORRECT — dedicated dependency update
# PR title: "chore(deps): bump requests 2.28.0 → 2.31.0"
# Single-purpose, reviewable, revertable
```

## 5. Config & secrets — never hardcoded

- Secrets live in environment variables — never in source, never in config committed to git
- No hardcoded URLs, hostnames, or credentials — inject via config/env
- Feature flags gate incomplete or risky work, not comments

```python
# ❌ WRONG — hardcoded secret
API_KEY = "sk-live-abc123"

# ✅ CORRECT — from environment
API_KEY = os.environ["API_KEY"]
```

## 6. Logging — structured, no PII, appropriate levels

- Structured logs (key-value or JSON) — not free-text string concatenation
- Never log PII (email, phone, full name, tokens) — redact or omit
- Log level matches severity: `debug` for tracing, `warn` for recoverable issues, `error` for failures needing attention

```python
# ❌ WRONG — PII in logs, wrong level
logger.error(f"User {user.email} logged in")

# ✅ CORRECT
logger.info("user_login", extra={"user_id": user.id})
```
