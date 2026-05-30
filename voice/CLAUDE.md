# voice — Claude guidance

Per-agent harness — the **agent basement**. Rust workspace; a single `voice` binary that
Harmony spawns **one process per agent**. Voice reads a resolved role manifest, sets up a git
worktree, and runs a **native agent loop**: it drives the model through the linked `echo`
library and executes tools (from MCP) on the model's behalf, streams structured progress,
writes a run report, and exits.

## Status: spec-only

No Rust source code exists yet — there is no `crates/` directory on disk. All design lives in
`spec/`. Write spec before code.

## Spec map

| File | What it covers |
|------|----------------|
| `spec/overview.md` | What Voice is, scope, non-goals, language rationale |
| `spec/protocol.md` | Spawn contract: env vars, progress stream, exit codes, signalling |
| `spec/roles.md` | Consuming the role manifest; runtime context assembly |
| `spec/agent-loop.md` | The native loop: echo calls, MCP tool execution, built-in signals |
| `spec/workspace.md` | Git worktree setup, cleanup, cwd-pin invariant |
| `spec/report.md` | Run report JSON schema written on exit |

## Package layout (planned)

| Crate | Purpose |
|-------|---------|
| `crates/core` | Library: env parsing, worktree ops, role-manifest model, agent loop, MCP↔echo bridge, report schema |
| `crates/voice` | Binary: entry point, owns exit codes |

Depends on the `echo` crate (`../echo`), linked **in-process** — the reason Voice is Rust
(connection reuse across turns; types shared with echo at compile time). Edition 2024,
resolver 3.

## Build

```sh
# from voice/
cargo build
cargo run -- --help
cargo test --workspace
cargo clippy --workspace --all-targets
cargo fmt --all
```

## Key constraints

- **No model client of its own.** All provider/model I/O goes through the linked `echo` crate.
- **echo is MCP-agnostic.** Voice owns the MCP↔echo bridge: MCP tools → echo `Tool` schemas;
  `tool_call` events → MCP execution → `ToolResult`.
- **stdout is protocol** (`score.voice-event/v1` JSONL), **stderr is logs.** Never free-form
  text on stdout.
- **Harmony resolves config; Voice assembles runtime context** (reads repo `AGENTS.md`/
  `CLAUDE.md`, launches MCP, builds the echo `Context`).
- **One agent per process.** No internal multi-agent threading; sub-agents (if ever) are
  requested from Harmony as child Voice processes.

## Cross-package contract

See [`../CONTRACT.md`](../CONTRACT.md) for the spawn env vars, role manifest, progress-stream
and exit-code contract, and the `voice`↔`echo` API. Update `CONTRACT.md` before changing any of
them.
