# echo — Claude guidance

Personal conversational AI companion. A readline REPL written in OCaml that wraps one or more
AI backends and feels like Pi — warm, stateful, always-on — while living fully in the terminal.

## Status: scaffolded — no logic yet

Dune project is in place with `bin/main.ml` (subcommand dispatch), `lib/{message,session,
config,repl}.ml`, and `lib/backend/{backend_intf,registry,claude_cli,claude_api,openai,
custom}.ml`; compiles cleanly. All backend logic is TODO. Write spec before adding logic.

## Spec map

| File | What it covers |
|------|----------------|
| `spec/overview.md` | Product goals, guiding principles, non-goals |
| `spec/backends.md` | Provider adapter interface and each supported backend |
| `spec/session.md` | Conversation session model, history, persistence |
| `spec/config.md` | Configuration schema — API keys, defaults, per-profile settings |

## Package layout (planned)

```
echo/
  bin/
    main.ml          # entry point — arg parsing, profile selection, REPL loop
  lib/
    backend/         # one module per provider adapter
      claude_cli.ml  # wraps `claude -p` subprocess
      claude_api.ml  # direct Anthropic REST API (BYOK)
      openai.ml      # OpenAI-compatible REST API (BYOK / ChatGPT key)
      custom.ml      # any OpenAI-compat endpoint (Ollama, local LM, etc.)
    session.ml       # in-memory conversation state + disk persistence
    config.ml        # config file loading, env var resolution
    repl.ml          # readline loop, prompt rendering, streaming display
  spec/
  dune-project
  dune              # (root lib + bin targets)
```

## Build

```sh
# from echo/
opam install . --deps-only    # install OCaml deps (once)
dune build                    # build the binary
dune exec echo -- chat        # start a session
dune test                     # run tests
```

Edition: OCaml ≥ 5.1, dune ≥ 3.16.

## Key constraints

- **No model logic inside echo.** Echo routes messages to backends; it does not prompt-engineer,
  chain calls, or own tool definitions. That belongs to the backend or a future skill layer.
- **Streaming first.** All backends must surface tokens as they arrive; blocking until a full
  response is a fallback, not the default.
- **Offline-tolerant.** History is always flushed to disk before sending a request. A crash or
  network failure must never lose a user message.

## Cross-package contract

Echo is standalone — it does not talk to Harmony and is not dispatched by Harmony.
If that changes, `../CONTRACT.md` must be updated first.
