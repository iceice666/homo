# homo

Personal sandbox. Four packages, all spec-phase.

| Package | Role | Language |
|---------|------|----------|
| `aria/` | Desktop UI — what you see | SwiftUI (macOS) · GTK (Linux) |
| `harmony/` | State manager — what the engine knows | Elixir/OTP |
| `voice/` | Agent harness — what an agent run does | Rust |
| `echo/` | Conversational AI companion — who you talk to | OCaml |

## How they fit together

```
┌─────────────────────────────────────────┐
│  Aria  (desktop UI)                     │
│  board · ticket detail · run report     │
│  runtimes inventory                     │
└────────────────┬────────────────────────┘
                 │  Phoenix Channels / WebSocket (see CONTRACT.md)
┌────────────────▼────────────────────────┐
│  Harmony  (Elixir/OTP daemon)           │
│  two-layer state model · WIP limits     │
│  file-watcher · dispatch                │
└────────────────┬────────────────────────┘
                 │  subprocess spawn (see CONTRACT.md)
┌────────────────▼────────────────────────┐
│  Voice  (per-ticket runner)             │
│  sets up worktree · spawns external CLI │
│  (claude / codex / gemini / …)          │
│  writes run report                      │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  echo  (standalone companion REPL)      │
│  not part of the dispatch loop          │
└─────────────────────────────────────────┘
```

Project state lives as YAML files inside each project repo under `.score/tickets/`.
Harmony watches those files; Aria displays them; Voice acts on them. `echo` stands apart —
a personal conversational AI companion that runs on its own.

Agents come from external CLIs you already have installed — no model client is bundled.

## Cross-package contract

See [`CONTRACT.md`](CONTRACT.md) for the on-disk layout, wire protocol surface, and spawn
protocol that `aria`, `harmony`, and `voice` implement against. (`echo` is standalone and is
not covered by the contract.)

## Inspiration

Design draws on [openai/symphony](https://github.com/openai/symphony) (two-layer state model,
config-as-code, structured run reports) and [multica-ai/multica](https://github.com/multica-ai/multica)
(board-as-home, agents as first-class assignees, runtimes inventory).

## Status

All four packages are **spec-only**. No implementation code exists yet.
