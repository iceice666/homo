# Partitura

Personal sandbox. Four packages, all spec-phase.

| Package | Role | Language |
|---------|------|----------|
| `aria/` | Desktop UI — what you see | SwiftUI (macOS) · GTK (Linux) |
| `harmony/` | State manager — what the engine knows | Elixir/OTP |
| `voice/` | Agent harness — what an agent run does | Rust |
| `echo/` | Unified LLM client — how requests reach a model | Rust |

## How they fit together

```
┌─────────────────────────────────────────┐
│  Aria  (desktop UI)                     │
│  board · ticket detail · run report     │
│  providers / models                     │
└────────────────┬────────────────────────┘
                 │  Phoenix Channels / WebSocket (see CONTRACT.md)
┌────────────────▼────────────────────────┐
│  Harmony  (Elixir/OTP daemon)           │
│  two-layer state model · WIP limits     │
│  file-watcher · role catalog · dispatch │
└────────────────┬────────────────────────┘
                 │  subprocess spawn, one per agent (see CONTRACT.md)
┌────────────────▼────────────────────────┐
│  Voice  (per-agent runner, Rust)        │
│  worktree · native agent loop · MCP     │
│  writes run report                      │
└────────────────┬────────────────────────┘
                 │  links in-process (crate)
┌────────────────▼────────────────────────┐
│  echo  (unified LLM client, Rust)       │
│  Context → stream/complete · providers  │
│  + thin CLI / test REPL for humans      │
└────────────────┬────────────────────────┘
                 │  HTTPS
            LLM provider (Anthropic · OpenAI)
```

Project state lives as YAML files inside each project repo under `.score/tickets/`.
Harmony watches those files; Aria displays them; Voice acts on them. Voice runs a native
agent loop and reaches models through `echo`, the shared LLM client. `echo` also ships a thin
CLI with a REPL for talking to a model directly.

No agent model client is bundled per-CLI — `echo` is the one place provider abstraction, auth,
and streaming live.

## Cross-package contract

See [`CONTRACT.md`](CONTRACT.md) for the on-disk layout, wire protocol surface, spawn
protocol, and the `voice`↔`echo` API that `aria`, `harmony`, `voice`, and `echo` implement
against.

## Inspiration

Design draws on [openai/symphony](https://github.com/openai/symphony) (two-layer state model,
config-as-code, structured run reports) and [multica-ai/multica](https://github.com/multica-ai/multica)
(board-as-home, agents as first-class assignees, runtimes inventory).

## Status

All four packages are **spec-only**. No implementation code exists yet.
