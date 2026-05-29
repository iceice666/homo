# Voice

The per-ticket agent harness for the **Partitura** system. Written in Rust.

One Voice invocation = one external-CLI run against one isolated git worktree. Harmony spawns
the `voice` binary as a subprocess when a ticket is dispatched. Voice sets up the workspace,
invokes the CLI agent (`claude`, `codex`, `gemini`, …), streams its output, and writes a
structured JSON run report on exit.

Voice does **not** call LLM APIs or hold API keys — those belong to the external CLI.

## Package layout (planned)

```
crates/
  core/   library — env, worktree, adapters, report schema
  voice/  binary  — entry point, exit codes
```

## Docs

All design is in [`spec/`](spec/), and the Harmony↔Voice spawn protocol is in
[`../CONTRACT.md`](../CONTRACT.md). No implementation code exists yet.

## Part of Partitura

One of four packages in the **Partitura** system. Voice is the agent harness —
[`harmony`](../harmony/) (the Elixir/OTP state manager) spawns it per ticket, and
[`aria`](../aria/) (the desktop UI) shows the run reports it writes. [`echo`](../echo/) is a
standalone companion REPL, not part of this loop.

## Status: spec-only
