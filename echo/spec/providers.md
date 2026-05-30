# echo — Providers

A provider adapter maps echo's `Context`/`stream` (see `api.md`) onto one wire API: build the
request, parse the streaming response into echo's event union, normalise usage/errors. Adding a
provider does not change callers.

## v1 providers

| `Provider` | Wire API | Auth |
|------------|----------|------|
| `Anthropic` | Anthropic Messages (`/v1/messages`, `stream: true`) | `ANTHROPIC_API_KEY` (or config) |
| `OpenAI` | OpenAI Chat Completions / Responses | `OPENAI_API_KEY` (or config) |
| `OpenAiChatGpt` | OpenAI Responses via Codex OAuth | ChatGPT-subscription **OAuth** token store |

These three are the v1 scope. Everything below "Deferred" is out of scope until specced.

---

### `Anthropic` — Messages API

- Endpoint: `https://api.anthropic.com/v1/messages`, `stream: true`.
- Auth: `ANTHROPIC_API_KEY` env (preferred) or `providers.anthropic.api_key` in config
  (chmod-600). Echo holds no other Anthropic credential.
- Streaming: Anthropic SSE (`content_block_start` / `content_block_delta` / `message_delta`)
  parsed into echo's `text_*` / `thinking_*` / `toolcall_*` / `done` events.
- Prompt caching: `cache_control: { type: "ephemeral" }` on the system block and the last few
  turns on long contexts, to cut cost.
- Tools: Anthropic `tools` + `tool_use` / `tool_result` map directly to echo's `Tool` /
  `ToolCall` / `ToolResult`.

### `OpenAI` — API key

- Endpoint: Chat Completions (`/v1/chat/completions`) or Responses, `stream: true`.
- Auth: `OPENAI_API_KEY` env or config. `OPENAI_ORG_ID` optional.
- Streaming: `choices[].delta` (Chat Completions) or Responses events → echo's event union.
- Tools: OpenAI function-calling; tool-call arguments stream as partial JSON, best-effort
  parsed during `toolcall_delta`.

### `OpenAiChatGpt` — ChatGPT-subscription OAuth

- Uses an OpenAI **OAuth** token (the Codex/ChatGPT-subscription path) rather than a metered
  API key, so a ChatGPT Plus/Pro subscription can drive requests.
- Auth: an OAuth flow that obtains and refreshes a token, stored in echo's local token store
  (see `config.md`). `echo login openai-chatgpt` performs the flow; `echo logout` clears it.
- Wire API: OpenAI Responses, same event mapping as `OpenAI`.

---

## Auth resolution order

For a given provider, echo resolves credentials in order:

1. Explicit `Options.api_key` (library callers).
2. Provider env var (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`).
3. OAuth token from the token store (for OAuth providers).
4. `providers.<name>.api_key` in `config.toml` (discouraged; chmod-600).

If none resolve, the call fails before any network I/O with a clear "no credentials for
<provider>" error.

---

## Adding a provider

1. Write its section here (endpoint, auth, streaming mapping, tool mapping).
2. Add a `Provider` variant and its model metadata to `api.md`'s model registry.
3. Implement the adapter; map the wire stream onto echo's event union.
4. Add a config section to `config.md`.

---

## Deferred (not v1)

- **Anthropic subscription OAuth** (Claude Pro/Max) — symmetric to `OpenAiChatGpt`; trivial
  follow-up since the OAuth/token-store machinery already exists.
- **OpenAI-compatible / local endpoints** (Ollama, vLLM, LM Studio) via a `Custom { base_url }`
  provider — local models also make echo's one-shot CLI handshake cost negligible.
- Google / Vertex, Mistral, Bedrock, OpenRouter, and the rest of the `pi-ai` provider set.
