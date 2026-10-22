---
name: rust-coding
description: Rust coding rules — safety invariants, thiserror/anyhow error split, concurrency and locking, Tokio hygiene, API shape, serde wire compatibility, and the fmt/clippy/test gate. Extends `coding` + `coding-agent-guardrails`.
version: 0.1.0
triggers:
  - "rust"
  - "cargo"
  - "tokio"
  - "/rust-coding"
globs:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
  - "**/clippy.toml"
  - "**/rust-toolchain*"
---

# Rust coding

Rust rules — apply on every `.rs` file you touch.

## 1. Scope & layering

- **Read the `coding-agent-guardrails` skill first, then the `coding` skill, before applying anything here.** Both are always in force on Rust work:
  - `coding-agent-guardrails` — file size, code organization, VCS discipline, build behavior
  - `coding` — error handling, testing, API design, dependency hygiene, config/secrets, logging
- This skill does not replace either — it adds Rust-specific rules on top
- Where this skill is tighter than a parent rule for `*.rs`, this skill wins

## 2. Safety & invariants

- `#![forbid(unsafe_code)]` at the root of every crate (lib and bin). A crate with a documented need (FFI, PTY, SIMD) uses `#![deny(unsafe_code)]` instead, and every `unsafe` block carries a `// SAFETY:` comment stating the invariant that makes it sound — not what the code does.
- **Zero `unwrap()` / `expect()` in production library code.** Return `Result`/`Option` and propagate with `?`. Panics are for broken programmer invariants, never for bad input, missing files, or closed sockets.
- `expect("reason")` is acceptable only in `main.rs`, tests, and on invariants the type system already guarantees. Enforce with `#![deny(clippy::unwrap_used, clippy::expect_used)]` in library crates (allow in `#[cfg(test)]`).
- Never use `std::mem::transmute`, `unsafe impl Send/Sync`, or raw pointers to escape a borrow-checker fight. Restructure ownership instead (`Arc`, channel, owned data); if truly stuck, escalate.
- Do not silence a compiler error by sprinkling `.clone()` — first check the clone doesn't reintroduce a stale-read race the borrow was preventing.

```rust
// ❌ WRONG — panics on malformed input
let port: u16 = env::var("PORT").unwrap().parse().unwrap();

// ✅ CORRECT — failure is a value
let port: u16 = env::var("PORT")?.parse()?;
```

## 3. Error handling

- **Library crates:** define a typed error enum with `thiserror::Error`. Callers match on variants. Never expose `String`, `Box<dyn Error>`, or `anyhow::Error` as a library's public error type.
- **Binary / CLI edges:** `anyhow::Result` in `main` and top-level command dispatch, where the goal is reporting to a human or log, not programmatic matching.
- Preserve context across layers: `#[from]` / `#[source]` in thiserror variants, `.context("…")` in anyhow. A bare `?` that drops which layer failed at a module boundary is a bug.
- Never swallow errors with `let _ = fallible();`. If ignoring is deliberate, write `.ok();` plus a comment saying why.

```rust
// ✅ library error — typed, sourced
#[derive(Debug, thiserror::Error)]
pub enum StoreError {
    #[error("record {0} not found")]
    NotFound(RecordId),
    #[error("storage failure")]
    Io(#[from] std::io::Error),
}

// ✅ binary edge — context for the human reading the log
let cfg = load(&path).with_context(|| format!("loading {}", path.display()))?;
```

## 4. Concurrency & locking

- **Prefer message passing over shared mutable state.** One task owns the data; others send it requests over `tokio::sync::mpsc` and get replies via `oneshot`. This is the actor pattern — it removes whole classes of lock bugs.
- **Never hold a lock guard across `.await`.** A `std::sync::Mutex` guard held over an await can deadlock the executor; drop the guard (scope it in a block) before awaiting. Use `tokio::sync::Mutex` only when the critical section genuinely must span an await.
- **Never hold a guard while calling anything that might lock the same mutex** — re-entrant acquisition self-deadlocks (a hang, not a failure). Do not expose raw guarded accessors (`fn conn(&self) -> MutexGuard<_>`); expose narrow single-purpose methods so callers cannot hold a guard across another call.
- **Keyed state stays keyed.** If correctness needs per-key serialization (per session, per connection), use a per-key lock or actor-per-key — never collapse to one global `Mutex`/`RwLock` "to simplify". A coarser lock is a silent behavior change.
- **Single-writer fields are enforced by visibility, not comments.** The setter is `pub(crate)`/`pub(super)` in the owning module; everyone else gets a read-only accessor. Needing a second `pub` setter "to make it compile" is the bug the rule exists to catch.
- `Send`/`Sync` errors on a `tokio::spawn` are signal that the sharing model is wrong. Fix the model; never smuggle `Rc<RefCell<_>>` through `unsafe`.
- Bound every retry/poll loop (max attempts or `tokio::time::timeout`). No busy loops — use a channel, `Notify`, or timer. A hang is a failure of the same severity as a panic; run tests under an outer timeout (`timeout 120 cargo test`).

```rust
// ❌ WRONG — guard lives across the await
let mut g = state.lock().unwrap();
g.count += 1;
send(&g.peer).await;

// ✅ CORRECT — copy out, drop the guard, then await
let peer = { let mut g = state.lock()?; g.count += 1; g.peer.clone() };
send(&peer).await;
```

## 5. Async & Tokio hygiene

- **Never run blocking or CPU-heavy work on a Tokio worker.** Synchronous DB drivers, `std::fs` on large files, compression, hashing, and long loops go through `tokio::task::spawn_blocking` (or a dedicated worker thread).
- Batch related blocking work into one `spawn_blocking` call. For a single-writer resource (e.g. SQLite), funnel all access through one dedicated thread/task reached by an `mpsc` request channel instead of a `spawn_blocking` per call.
- Use `tokio::fs` / `tokio::process` / `tokio::net` inside async code, not their `std` equivalents.
- Every spawned task has an owner: keep the `JoinHandle` (or a `JoinSet`), propagate cancellation, and handle its `Result`. Fire-and-forget `tokio::spawn` that can fail silently is a swallowed error.
- Async code must be cancel-safe at each `.await` when used in `select!` — do not leave state half-updated between awaits.

```rust
// ❌ WRONG — sync hash on the async worker starves other tasks
async fn digest(buf: Vec<u8>) -> Hash { expensive_hash(&buf) }

// ✅ CORRECT
async fn digest(buf: Vec<u8>) -> Result<Hash, JoinError> {
    tokio::task::spawn_blocking(move || expensive_hash(&buf)).await
}
```

## 6. API shape

- **Newtypes over primitives.** Identifiers and units get their own type (`SessionId(String)`, not `String`) so they cannot be transposed at a call site.
- **Every serialized newtype is `#[serde(transparent)]`.** Without it the newtype serializes as a wrapper (`{"0":"…"}` / `["…"]`) instead of the bare inner value.
- **Struct fields private by default**; expose constructors and accessors. Public fields freeze your representation and block adding invariants later.
- **`Debug` on every public type** with meaningful output. Redact secrets by hand-writing `Debug` rather than leaking them into logs.
- Conversion names follow convention: `as_` (cheap borrow), `to_` (expensive copy), `into_` (consuming).
- Validate at the boundary and return `Result`; do not document "caller must not pass X".
- Mark types that may grow with `#[non_exhaustive]` when they are public, versioned API.

```rust
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct SessionId(String);
```

## 7. Wire compatibility (serde)

Applies to any struct or enum that crosses a process boundary (REST, WebSocket, files, IPC). Skip for purely internal types.

- JSON wire names are fixed by the contract, not by Rust style. Keep `snake_case` in Rust and map with `#[serde(rename_all = "camelCase")]` (or per-field `#[serde(rename = "…")]` for exceptions).
- Do not "improve" a wire shape because another one is more idiomatic. A divergence from the existing contract is a flagged, reviewed change — never a silent one.
- **Tolerant parsing where the peer is not under your control:** `Option<T>` + `#[serde(default)]` for fields that may be absent; do **not** use `#[serde(deny_unknown_fields)]` on inbound payloads (newer peers add fields); use `#[serde(other)]` on an `Unknown` enum variant for unrecognized tags.
- **Strict when you are the producer:** omit absent optionals with `#[serde(skip_serializing_if = "Option::is_none")]` so output is byte-stable.
- Pin the contract with a round-trip test against a captured JSON fixture — field names and shape, not just `Ok`.

```rust
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SessionInfo {
    pub session_id: SessionId,            // "sessionId"
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub worktree_id: Option<WorktreeId>,  // "worktreeId", absent when None
}
```

## 8. Tooling gate

A change is not done until all three are clean — run them, do not assume. Reviewers re-run them rather than trusting a "tests pass" report.

```bash
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace
```

- Prefer configuring lint levels in `[workspace.lints]` (Cargo.toml) over scattering `#![allow]` attributes. Every `#[allow(...)]` carries a one-line reason.
- Do not blanket-allow `clippy::pedantic` to make the gate pass. If pedantic is enabled at `warn`, use targeted `-D clippy::correctness -D clippy::suspicious -D clippy::complexity -D clippy::perf` instead of a bare `-D warnings`, so style lints stay informational.
- Wrap the invocation in one script (e.g. `scripts/rust-gate.sh`) so every run uses the same command, never a hand-typed variant.
- Once the workspace has third-party dependencies, add `cargo deny check` (licenses + advisories).
- Same compiler error shape twice in one file → grep the file for every other instance and fix them all in one pass, rather than rebuilding per occurrence.
