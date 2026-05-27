# echo — Configuration

## Config file location

```
~/.config/echo/config.toml
```

Created with `chmod 600` on first run. Echo aborts if the file exists but is world-readable.

## Full schema (annotated)

```toml
# ── Global defaults ──────────────────────────────────────────────────────────

default_backend  = "claude-cli"   # which backend to use if --backend is not set
default_profile  = "default"      # which profile to load if --profile is not set

[ui]
prompt_prefix    = "You"          # printed before the readline prompt
reply_prefix     = "echo"         # printed before streamed AI tokens
show_model       = true           # show active model in the reply prefix
streaming        = true           # stream tokens as they arrive; false = wait for full reply
color            = true           # ANSI colour in prefixes

# ── Backend configs ──────────────────────────────────────────────────────────

[backend.claude-cli]
cli_path         = "claude"
model            = ""             # blank → use CLI default

[backend.claude-api]
# api_key = "sk-ant-..."         # NOT recommended — use ANTHROPIC_API_KEY env var
model            = "claude-sonnet-4-6"
max_tokens       = 8192
prompt_caching   = true           # add cache_control on system + recent turns

[backend.openai]
# api_key = "sk-..."             # NOT recommended — use OPENAI_API_KEY env var
model            = "gpt-4o"
max_tokens       = 4096

[backend.custom]
base_url         = "http://localhost:11434/v1"
model            = "llama3.2"
api_key          = ""

# ── Per-profile overrides ─────────────────────────────────────────────────────
# Profiles inherit global defaults; any key here overrides the global value.

[profile.default]
backend          = "claude-cli"
system_prompt    = ""
max_context_tokens = 60000

[profile.work]
backend          = "claude-api"
system_prompt    = "You are a concise technical assistant. Prefer code over prose."
max_context_tokens = 100000

[profile.local]
backend          = "custom"
system_prompt    = ""
max_context_tokens = 8000
```

## Environment variables

All env vars override values in `config.toml`.

| Variable | Overrides |
|----------|-----------|
| `ECHO_BACKEND` | `default_backend` |
| `ECHO_PROFILE` | `default_profile` |
| `ANTHROPIC_API_KEY` | `backend.claude-api.api_key` |
| `OPENAI_API_KEY` | `backend.openai.api_key` |
| `OPENAI_ORG_ID` | OpenAI organisation header |
| `ECHO_CUSTOM_URL` | `backend.custom.base_url` |
| `ECHO_CUSTOM_API_KEY` | `backend.custom.api_key` |
| `NO_COLOR` | disables all ANSI output |

## CLI flags

CLI flags override env vars which override config file.

```
echo chat [options]

  --backend <name>      claude-cli | claude-api | openai | custom
  --profile <name>      profile name (default: value of default_profile)
  --session <id>        resume a specific session
  --new                 force a new session (ignore last active)
  --model <id>          override model for this session only
  --no-stream           disable streaming (wait for full reply)
  --no-color            disable ANSI colour
  --system <text>       override system prompt for this session only
  -v, --verbose         print config resolution, token counts, latency

echo sessions list [--profile <name>]
echo sessions show <session-id>
echo config show       # print resolved config (keys redacted)
echo --version
```

## Security notes

- `config.toml` must be `chmod 600`. Echo refuses to start otherwise.
- API keys in the config file are accepted but discouraged; env vars are preferred because
  they are not written to disk by echo and are not included in `echo config show` output.
- History files (`history.jsonl`) contain conversation content but never API keys.
  They are stored with `chmod 600` in the profile directory.
