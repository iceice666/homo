# echo — Overview

## What echo is

Echo is a personal conversational AI companion that runs as a readline REPL in the terminal.
It is the homo project's answer to Pi: a warm, stateful, always-available AI that you talk to
across sessions rather than in one-off prompts.

Echo is **not** an agent harness (that is `voice`). It does not manage tickets, spawn
subprocesses on codebases, or integrate with Harmony. It is a conversation loop.

## Goals

1. **Feel personal.** Each profile stores its own conversation history so the AI has context
   spanning sessions — what you talked about yesterday, last week.

2. **Stay in the terminal.** A readline REPL with streaming output. No browser, no Electron,
   no separate server process.

3. **Be backend-agnostic.** Support Claude (via CLI subprocess or direct API), OpenAI-compatible
   APIs (including ChatGPT keys and local models), and any OpenAI-compatible endpoint a user
   can configure.

4. **Own nothing sensitive.** API keys live in env vars or a local config file with user-only
   permissions (`chmod 600`). Echo never uploads or logs key material.

5. **Survive interrupts.** User messages are written to disk before the backend is called.
   Ctrl-C during streaming is clean — partial streamed tokens are discarded; history stays
   consistent.

## Non-goals

- Tool use / function calling inside echo itself (the backend may expose tools; echo does not
  orchestrate them beyond passing the stream through).
- A GUI or TUI widget set — readline only for now.
- Multi-user or networked use.
- Integration with Harmony / ticket lifecycle (deferred; if added, `CONTRACT.md` is updated
  first).

## Architecture sketch

```
┌─────────────────────────────────────┐
│               bin/main.ml           │
│  arg parse → profile load → REPL    │
└───────────────┬─────────────────────┘
                │
        ┌───────▼──────┐
        │   lib/repl   │  readline loop, streaming render
        └───────┬──────┘
                │  send_message / stream_response
        ┌───────▼───────────┐
        │  lib/backend/*    │  adapter per provider
        └───────┬───────────┘
                │  HTTP / subprocess
      ┌─────────▼──────────────┐
      │  AI provider           │
      │  (Anthropic / OpenAI   │
      │   / claude CLI / local)│
      └────────────────────────┘
```

`lib/session` sits alongside the repl, providing the in-memory message list and flushing it
to `~/.config/echo/<profile>/history.jsonl` before each outbound call.

## Guiding principles

- **Spec first.** No OCaml source until the spec for that module is written.
- **Thin adapter, thick session.** Each backend does only what the provider requires.
  Session management, system-prompt injection, and history truncation are backend-agnostic
  and live in `lib/session`.
- **Streaming is the contract.** Any backend that cannot stream must simulate it (chunk on
  newlines). The REPL always prints tokens as they arrive.
- **One binary.** `echo` is a single compiled binary with no runtime dependencies beyond
  the system's TLS stack.
