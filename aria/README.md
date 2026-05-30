# Aria

The desktop UI for the **Partitura** system. Aria is your window into project state — a board of
tickets, a run-report panel when an agent finishes, and a view of the available providers and
models that agents can run on.

Two parallel native implementations, sharing only the protocol contract:

| Platform | Stack |
|----------|-------|
| macOS | SwiftUI (native) |
| Linux | GTK 4 + Relm4 (Elm MVU in Rust) |

Aria is a **thin client** over Harmony — all logic lives in the state manager; Aria only
renders what Harmony reports and forwards user intent.

## Docs

All design is in [`spec/`](spec/). No implementation code exists yet.

## Part of Partitura

One of four packages in the **Partitura** system. Aria is the UI layer — it talks to
[`harmony`](../harmony/) (the Elixir/OTP state manager), which dispatches [`voice`](../voice/)
(the agent harness). [`echo`](../echo/) is the unified LLM client that Voice links for model calls.

## Status: spec-only
