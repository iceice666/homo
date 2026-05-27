# Aria

The desktop UI for the **homo** system. Aria is your window into project state — a board of
tickets, a run-report panel when an agent finishes, and a live runtimes inventory showing
which CLI agents are detected on this machine.

Two parallel native implementations, sharing only the protocol contract:

| Platform | Stack |
|----------|-------|
| macOS | SwiftUI (native) |
| Linux | GTK 4 + Relm4 (Elm MVU in Rust) |

Aria is a **thin client** over Harmony — all logic lives in the state manager; Aria only
renders what Harmony reports and forwards user intent.

## Docs

All design is in [`spec/`](spec/). No implementation code exists yet.

## Part of homo

One of four packages in the **homo** system. Aria is the UI layer — it talks to
[`harmony`](../harmony/) (the Elixir/OTP state manager), which dispatches [`voice`](../voice/)
(the agent harness). [`echo`](../echo/) is a standalone companion REPL, not part of this loop.

## Status: spec-only
