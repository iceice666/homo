# echo — Configuration

Echo reads configuration from a TOML file, environment variables, and (for OAuth providers) a
local token store. Library callers may also pass values directly via `Options`.

Precedence (highest first): `Options` (library) / CLI flag → env var → token store → config
file.

## Config file

```
~/.config/echo/config.toml
```

Created with `chmod 600` on first run. Echo refuses to start if it exists but is
world-readable. API keys in this file are accepted but discouraged — prefer env vars (not
written to disk) or the OAuth token store.

```toml
# ── Defaults ───────────────────────────────────────────────────────────────
default_model = "anthropic/claude-opus-4-8"   # provider/id used when --model is absent

# ── Providers ──────────────────────────────────────────────────────────────
[providers.anthropic]
# api_key = "sk-ant-..."        # prefer ANTHROPIC_API_KEY
max_tokens     = 8192
prompt_caching = true

[providers.openai]
# api_key = "sk-..."            # prefer OPENAI_API_KEY
# org_id  = "org-..."           # or OPENAI_ORG_ID
max_tokens     = 4096

[providers.openai-chatgpt]
# no api_key — uses the OAuth token store (echo login openai-chatgpt)

# ── REPL (interactive test mode only) ──────────────────────────────────────
[repl]
prompt_prefix = "you"
reply_prefix  = "echo"
streaming     = true
color         = true
```

## Token store

OAuth providers keep their tokens here (created chmod-600):

```
~/.config/echo/tokens/<provider>.json   # access + refresh token, expiry
```

`echo login <provider>` writes it; `echo logout <provider>` removes it. Tokens are refreshed
automatically before expiry and never logged or printed by `echo config show`.

## Environment variables

| Variable | Effect |
|----------|--------|
| `ANTHROPIC_API_KEY` | Anthropic credential |
| `OPENAI_API_KEY` | OpenAI credential |
| `OPENAI_ORG_ID` | OpenAI organisation header |
| `ECHO_MODEL` | overrides `default_model` |
| `ECHO_CONFIG` | alternate config file path |
| `NO_COLOR` | disable ANSI output |

## Security notes

- `config.toml` and everything under `tokens/` must be `chmod 600`; echo refuses to start
  otherwise.
- Env-var credentials are preferred — they are not written to disk by echo.
- `echo config show` prints the resolved configuration with all secrets redacted.
