# Voice — Overview

## What Voice is

Voice is the per-ticket agent harness. Harmony spawns one `voice` binary per ticket dispatch.
Voice is responsible for:

1. Setting up an isolated git worktree for the ticket.
2. Invoking the appropriate CLI adapter (e.g. `claude`, `codex`, `gemini`).
3. Relaying output back to Harmony line-by-line via stdout.
4. Writing a structured run report JSON to `VOICE_REPORT_PATH`.
5. Exiting with the correct exit code so Harmony can act on the result.

Voice does **not**:
- Call any LLM API directly.
- Hold API keys or OAuth credentials (the external CLI owns these).
- Write to the ticket YAML file (Harmony does this based on the exit code and run report).
- Manage WIP limits or dispatch decisions (Harmony owns these).

## Implementation language

**Rust.** Single workspace at `voice/` with two crates:

- `crates/core` — library: env parsing, worktree management, adapter trait + impls,
  run report schema.
- `crates/voice` — binary: entry point, orchestrates core, owns exit codes.

## Design intent

Voice is intentionally thin. Most interesting logic lives in the CLI adapters
(`spec/cli-adapters.md`) and the run report schema (`spec/report.md`). The binary
itself is a coordinator: read env vars → set up worktree → run adapter → write report → exit.

## Scope of v1

Must exist before shipping:

1. Read and validate all `VOICE_*` env vars (see `spec/protocol.md`)
2. Set up git worktree at `VOICE_WORKSPACE` (see `spec/workspace.md`)
3. Resolve and invoke the CLI adapter for `VOICE_CLI` (see `spec/cli-adapters.md`)
4. Stream output lines to stdout (Harmony relays these as `run:progress` events)
5. Write run report JSON on exit (see `spec/report.md`)
6. Exit with correct code
7. Handle `SIGTERM` gracefully (write partial report, clean up worktree)

Out of scope for v1:
- Tool-call interception (agent runs in autonomous mode)
- Multi-turn session management (single autonomous run per invocation)
- Workspace reuse across runs (each invocation gets a fresh worktree)
