# echo — Claude guidance

The **unified LLM client** for Partitura. One codebase, two shapes: a **library crate** that
`voice` links in-process for every model call, and a **thin CLI** (one-shot + a test REPL) for
humans and non-Rust callers. Shapes follow [`pi-ai`](https://www.npmjs.com/package/@earendil-works/pi-ai):
a `Context` goes in, a stream of typed events comes out, across all providers.

## Status: spec-only

No Rust source exists yet. All design lives in `spec/`. Write spec before code.

## Spec map

| File | What it covers |
|------|----------------|
| `spec/overview.md` | What echo is, delivery (crate + CLI), goals, non-goals |
| `spec/api.md` | Library API: `Context`/`Message`/`Tool`/`Model`, `stream`/`complete`, event union |
| `spec/providers.md` | v1 providers (Anthropic · OpenAI · OpenAI ChatGPT OAuth) + auth |
| `spec/cli.md` | The thin CLI: one-shot (`Context` JSON → JSONL events) and the test REPL |
| `spec/config.md` | Config file, env vars, OAuth token store |

## Package layout (planned — Rust)

```
echo/
  Cargo.toml          # workspace
  crates/
    core/             # library crate `echo` — the LLM client API
      src/
        lib.rs
        context.rs    # Context, Message, Block, Tool
        model.rs      # Model, Provider, registry
        event.rs      # the streaming event union
        client.rs     # stream / complete
        provider/     # one adapter per provider
          anthropic.rs
          openai.rs
          openai_chatgpt.rs
        auth.rs       # env keys + OAuth token store
    cli/              # binary `echo` — one-shot + REPL, links crate `echo`
      src/main.rs
  spec/
```

`voice` depends on crate `echo` (path/workspace dependency). Edition 2024.

## Build

```sh
# from echo/
cargo build
cargo run -p echo-cli -- run --model anthropic/claude-opus-4-8 < context.json
cargo test --workspace
cargo clippy --workspace --all-targets
cargo fmt --all
```

## Key constraints

- **No agent logic.** No loop, no tool execution, no MCP, no prompt assembly from skills. Echo
  takes `tools` as schemas and emits `tool_call` events; the caller runs them.
- **Streaming is the interface.** `complete` is a thin collector over `stream`.
- **Secrets stay local.** Keys from env or chmod-600 config; OAuth tokens in the token store.
  Never logged, never in `echo config show`.
- **Provider-agnostic callers.** Adding a provider must not change the `Context`/`stream` API.

## Cross-package contract

`voice` links echo in-process, so the crate API is a contract surface — see the "Voice ↔ echo"
section of [`../CONTRACT.md`](../CONTRACT.md). Update `CONTRACT.md` before changing the
`Context`/event shapes or the CLI's JSON I/O.
