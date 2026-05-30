# echo — Library API

The crate `echo` (`crates/core`) is the real interface; the CLI (`cli.md`) is a thin wrapper
over it. Shapes follow [`pi-ai`](https://www.npmjs.com/package/@earendil-works/pi-ai), mapped
to idiomatic Rust. Types below are illustrative, not final signatures.

---

## Context — the request

```rust
pub struct Context {
    pub system_prompt: Option<String>,
    pub messages: Vec<Message>,
    pub tools: Vec<Tool>,          // schemas only; echo never executes them
}
```

`Message` is a tagged union; content is a list of typed blocks (blocks may interleave in a
stream, so each carries an index — see events):

```rust
pub enum Message {
    User { content: Vec<Block> },
    Assistant { content: Vec<Block>, stop_reason: Option<StopReason> },
    ToolResult { tool_call_id: String, content: Vec<Block>, is_error: bool },
}

pub enum Block {
    Text { text: String },
    Thinking { text: String, signature: Option<String> },  // signature preserves
    Image { /* source: bytes | url, media_type */ },        //   redacted reasoning
    ToolCall { id: String, name: String, args: serde_json::Value },
}
```

A `Tool` is a name + description + JSON-Schema parameters:

```rust
pub struct Tool { pub name: String, pub description: String, pub parameters: serde_json::Value }
```

Voice builds `tools` from its MCP servers (see `voice/spec/agent-loop.md`); echo treats them as
opaque schemas.

---

## Model — the target

```rust
pub struct Model { pub provider: Provider, pub id: String, /* limits, pricing, caps */ }

pub fn get_model(provider: Provider, id: &str) -> Option<Model>;
pub fn get_models(provider: Provider) -> Vec<Model>;
pub fn providers() -> Vec<Provider>;
```

`Provider` for v1: `Anthropic`, `OpenAI`, `OpenAiChatGpt` (ChatGPT-subscription OAuth). See
`providers.md`.

---

## Entry points

```rust
pub async fn complete(model: &Model, ctx: &Context, opts: &Options) -> Result<Assistant, Error>;

pub fn stream(model: &Model, ctx: &Context, opts: &Options) -> EventStream;
// EventStream: Stream<Item = Event> + a `.result()` future returning the final Assistant
```

`stream` is the native call; `complete` collects a stream into the final message. `Options`
carries `max_tokens`, `temperature`, `thinking` level (`off`/`minimal`/`low`/`medium`/`high`),
`max_retries`, and an abort handle.

---

## Event union

Mirrors Pi. Every event carries the `partial` assistant message so far and the
`content_index` of the block it belongs to (blocks can interleave):

| Event | Meaning |
|-------|---------|
| `start` | request accepted, generation beginning |
| `text_start` / `text_delta` / `text_end` | a text block |
| `thinking_start` / `thinking_delta` / `thinking_end` | a reasoning block |
| `toolcall_start` / `toolcall_delta` / `toolcall_end` | a tool call; `args` stream as partial JSON, best-effort parsed |
| `done` | finished; `reason ∈ stop | length | tool_use` |
| `error` | `reason ∈ aborted | error` with detail |

This is the union the CLI serialises as `score.echo-event/v1` JSONL (`cli.md`) and that
`voice` maps up into `score.voice-event/v1` for Harmony (`CONTRACT.md`).

---

## Normalisation (echo's job, not the caller's)

- **Usage & cost.** Every response carries `Usage { input, output, cache_read }`; echo computes
  cost from the model's pricing.
- **Thinking levels.** A unified level is mapped to each provider's native knob; redacted/
  encrypted reasoning is preserved via a signature so a context can move between models.
- **Retries.** Bounded retries on transient/5xx with a delay cap; if a provider asks to wait
  longer than the cap, echo fails fast so the caller can decide.
- **Context overflow.** A normalised `is_context_overflow(err)` across providers so the caller
  (voice) can compact and retry.

---

## What echo does not do

No tool execution, no MCP, no multi-turn loop, no prompt assembly from skills, no persistence.
A `tool_call` event is the end of echo's involvement with that tool — the caller runs it and
appends a `ToolResult` to the next `Context`.
