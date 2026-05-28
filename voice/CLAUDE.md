# voice — Claude guidance

Per-ticket agent harness. Rust workspace; a single `voice` binary that reads env vars from
Harmony, sets up a git worktree, invokes an external CLI adapter, streams output, writes a
structured run report, and exits.

## Status: scaffolded — no logic yet

Skeleton workspace is in place (`crates/core` lib + `crates/voice` bin); module stubs compile
cleanly. All business logic is TODO. Write spec before adding logic.

## Spec map

| File | What it covers |
|------|----------------|
| `spec/overview.md` | What Voice is, scope, non-goals |
| `spec/protocol.md` | Spawn contract: env vars, exit codes, Harmony interaction |
| `spec/cli-adapters.md` | How each external CLI (claude, codex, …) is normalised |
| `spec/workspace.md` | Git worktree setup, cleanup, cwd-pin invariant |
| `spec/report.md` | Run report JSON schema written on exit |

## Package layout (planned)

| Crate | Purpose |
|-------|---------|
| `crates/core` | Library: env parsing, worktree ops, adapter trait + impls, report schema |
| `crates/voice` | Binary: entry point, orchestrates core, owns exit codes |

Edition 2024, resolver 3.

## Build

Intended commands once the workspace is scaffolded (nothing is wired yet):

```sh
# from voice/
cargo build                      # build the binary
cargo run -- --help              # entry point
cargo test --workspace           # all tests
cargo clippy --workspace --all-targets
cargo fmt --all
```

## Key constraints

Voice does **not** contain a model client, OAuth, or API keys — those belong to the external
CLI being wrapped. Voice only sets up the worktree, invokes the adapter, relays output, and
writes the run report.

## Cross-package contract

See `../CONTRACT.md` for the env vars Harmony passes and the exit codes Voice must return.
Update `CONTRACT.md` before changing the protocol.
