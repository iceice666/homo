# Voice

The per-agent harness for the **Partitura** system — the *agent basement*. Written in Rust.

One Voice invocation = one agent run against one isolated git worktree. Harmony spawns the
`voice` binary, one process per agent, when a ticket is dispatched. Voice reads a resolved
**role manifest**, sets up the worktree, and runs a **native agent loop**: it drives the model
through the linked [`echo`](../echo/) library and executes tools (from MCP) on the model's
behalf, streams structured progress, and writes a JSON run report on exit.

Voice does **not** wrap an external agent CLI, and does **not** implement model/provider logic
— that lives in `echo`, which Voice links in-process (the reason Voice is Rust: connection
reuse across turns and types shared at compile time).

## Package layout (planned)

```
crates/
  core/   library — env, worktree, role manifest, agent loop, MCP↔echo bridge, report schema
  voice/  binary  — entry point, exit codes
```

Depends on the `echo` crate (`../echo`).

## Docs

All design is in [`spec/`](spec/); the spawn protocol and `voice`↔`echo` API are in
[`../CONTRACT.md`](../CONTRACT.md). No implementation code exists yet (the skeleton still
reflects the older CLI-adapter model, pending rework).

## Part of Partitura

One of four packages. [`harmony`](../harmony/) (Elixir/OTP state manager) spawns Voice per
agent; [`aria`](../aria/) (desktop UI) shows the run reports it writes; [`echo`](../echo/) is
the LLM client Voice links for every model call.

## Status: spec-only
