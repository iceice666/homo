# Voice — Overview

## What Voice is

Voice is the **agent basement**: a native per-agent harness. Harmony spawns one `voice` process
per dispatch (**one process per agent**). Voice runs an agent loop itself — it drives the model
through the linked `echo` library and executes tools — rather than wrapping an external agent
CLI. Responsibilities:

1. Set up an isolated git worktree for the ticket (`spec/workspace.md`).
2. Read the resolved role manifest and assemble the model context (`spec/roles.md`).
3. Run the agent loop: `echo` model calls + MCP tool execution (`spec/agent-loop.md`).
4. Stream `score.voice-event/v1` progress to stdout for Harmony to relay.
5. Write a structured run report to `VOICE_REPORT_PATH`.
6. Exit with the correct code so Harmony can act.

Voice does **not**:
- Implement provider/model logic — that is `echo` (linked, not re-implemented).
- Choose models or resolve the global/repo role layering — Harmony does (`spec/roles.md`).
- Write the ticket YAML — Harmony does, from the exit code and report.
- Manage WIP limits or dispatch — Harmony does.

## Implementation language

**Rust.** One workspace at `voice/`:

- `crates/core` — library: env parsing, worktree management, role-manifest model, the agent
  loop, the MCP↔echo bridge, run-report schema.
- `crates/voice` — binary: entry point, owns exit codes.

Voice depends on the `echo` crate (`../echo`) and links it **in-process** — this is the whole
reason Voice is Rust: connection reuse across turns and types shared with `echo` at compile
time. See `CLAUDE.md`.

## Design intent

Voice is a thin, well-typed coordinator around two libraries: `echo` (model I/O) and an MCP
client (tools). The interesting variation between agents lives in *roles* (`spec/roles.md`),
not in code paths. The loop is identical for every role.

## Scope of v1

Must exist before shipping:

1. Read/validate `VOICE_*` env vars (`spec/protocol.md`).
2. Set up the git worktree (`spec/workspace.md`).
3. Load + apply the role manifest; read repo `AGENTS.md`/`CLAUDE.md` (`spec/roles.md`).
4. Run the agent loop via `echo`; launch MCP servers; bridge tools (`spec/agent-loop.md`).
5. Emit `score.voice-event/v1` progress on stdout (`spec/protocol.md`).
6. Built-in `needs_input` / `infeasible` signal tools → exit `4` / `3`.
7. Write the run report (`spec/report.md`); exit with the correct code.
8. Handle `SIGTERM` (write partial report, tear down MCP + worktree, exit `5`).

Out of scope for v1:
- Sub-agents (if added: Voice asks Harmony to spawn a child Voice — never threads internally).
- Workspace reuse across runs (every dispatch gets a fresh worktree).
- Providers beyond echo's v1 set.
