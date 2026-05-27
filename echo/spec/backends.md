# echo — Backends

## Backend interface

Every backend module in `lib/backend/` satisfies a single OCaml module type:

```ocaml
module type Backend = sig
  type config
  (** Provider-specific config (key, model, base URL, …). Loaded once at startup. *)

  val of_config : config -> (t, string) result
  (** Validate config and return a live handle, or an error string. *)

  val stream_message
    :  t
    -> history : Message.t list
    -> user_msg : string
    -> (string -> unit)   (* on_token callback *)
    -> (unit, string) result Lwt.t
  (** Send the conversation history + new user message.
      Call [on_token] for each streamed chunk.
      Returns [Ok ()] on clean finish or [Error reason] on failure. *)
end
```

`Message.t` is a shared record `{ role: [`User | `Assistant | `System]; content: string }`.

---

## Supported backends

### 1. `claude-cli` — subprocess wrapper

Wraps the `claude` CLI installed on the host system using the `-p` (print) flag.

**Auth:** Claude CLI's own login (`claude login`). Echo carries no Anthropic credentials.

**How it works:**

1. Echo serialises the conversation history as a single prompt string (system block + alternating
   turns) and passes it to `claude -p "<prompt>"`.
2. Stdout is streamed line-by-line as tokens.
3. On non-zero exit, the error string is returned.

**Config keys (in `~/.config/echo/config.toml`):**

```toml
[backend.claude-cli]
cli_path   = "claude"        # resolved from PATH if relative
model      = "claude-opus-4-7"  # passed as --model flag if set
```

**Caveats:**

- History injection is limited by the CLI's context window. Session truncation (see
  `session.md`) is applied before serialising.
- No native streaming from `claude -p`; echo reads stdout incrementally via Unix pipe.

---

### 2. `claude-api` — Anthropic REST API

Calls the Anthropic Messages API directly over HTTPS.

**Auth:** `ANTHROPIC_API_KEY` env var (preferred) or `api_key` in config (chmod-600 file).

**Endpoint:** `https://api.anthropic.com/v1/messages` with `stream: true`.

**Config keys:**

```toml
[backend.claude-api]
model          = "claude-sonnet-4-6"
max_tokens     = 8192
system_prompt  = ""              # injected as system turn; leave blank for none
```

**Wire format (abbreviated request):**

```json
{
  "model": "<model>",
  "max_tokens": 8192,
  "stream": true,
  "system": "<system_prompt>",
  "messages": [
    { "role": "user",      "content": "<turn>" },
    { "role": "assistant", "content": "<turn>" },
    …
  ]
}
```

Streaming uses Anthropic's SSE format (`event: content_block_delta`, `data: {…}`).
Echo parses `delta.text` from each `content_block_delta` event and calls `on_token`.

**Prompt caching:** `cache_control: { type: "ephemeral" }` is set on the system turn and on
the last four user turns when the conversation is longer than 1 000 tokens. This reduces
cost on long sessions.

---

### 3. `openai` — OpenAI REST API

Calls the OpenAI Chat Completions API. Accepts any OpenAI API key, including keys tied to
a ChatGPT Plus subscription.

**Auth:** `OPENAI_API_KEY` env var or config file.

**Endpoint:** `https://api.openai.com/v1/chat/completions` with `stream: true`.

**Config keys:**

```toml
[backend.openai]
model          = "gpt-4o"
max_tokens     = 4096
system_prompt  = ""
```

**Wire format:** Standard OpenAI messages array (`role` ∈ `system | user | assistant`).
Streaming uses the `data: {"choices":[{"delta":{"content":"…"}}]}` SSE format.

**Notes:**

- If the key is a ChatGPT subscription key (project key from platform.openai.com), behaviour
  is identical — no special handling needed.
- Organisation ID can be set via `OPENAI_ORG_ID` env var if required.

---

### 4. `custom` — OpenAI-compatible endpoint

For local models (Ollama, LM Studio, llama.cpp server) or any third-party provider that
speaks the OpenAI Chat Completions wire format.

**Auth:** Optional. `ECHO_CUSTOM_API_KEY` env var or blank if the server is unauthenticated.

**Config keys:**

```toml
[backend.custom]
base_url       = "http://localhost:11434/v1"
model          = "llama3.2"
api_key        = ""            # leave blank for local servers
system_prompt  = ""
```

The request/response format is identical to `openai` above. Echo substitutes `base_url` in
place of the OpenAI endpoint.

---

## Backend selection

The active backend is chosen at startup, in priority order:

1. `--backend <name>` CLI flag
2. `ECHO_BACKEND` env var
3. `default_backend` key in `~/.config/echo/config.toml`
4. If none set: `claude-cli` if `claude` is on PATH, else `claude-api` if
   `ANTHROPIC_API_KEY` is set, else error.

---

## Adding a new backend

1. Write `spec/backends.md` section for the new provider.
2. Implement `lib/backend/<name>.ml` satisfying `Backend`.
3. Register it in `lib/backend/registry.ml` (name → module mapping).
4. Add config section to `spec/config.md`.
5. Update this file's backend table.
