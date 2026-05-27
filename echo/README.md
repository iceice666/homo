# echo

A personal conversational AI companion for the terminal. Think [Pi](https://pi.ai) —
warm, stateful, always-on — but yours, in OCaml, with BYOK.

```
$ echo chat
echo> Hey! What's on your mind?
You: _
```

## Backends

| Flag | Backend | Auth |
|------|---------|------|
| `--backend claude-cli` | Wraps `claude -p` (subprocess) | Claude CLI login |
| `--backend claude-api` | Anthropic REST API | `ANTHROPIC_API_KEY` |
| `--backend openai` | OpenAI REST API | `OPENAI_API_KEY` (BYOK or ChatGPT key) |
| `--backend custom` | Any OpenAI-compatible endpoint | `ECHO_CUSTOM_URL` + optional key |

## Docs

All design is in [`spec/`](spec/). No implementation code exists yet.

## Part of homo

One of four packages in the **homo** system, alongside [`aria`](../aria/) (desktop UI),
[`harmony`](../harmony/) (state manager), and [`voice`](../voice/) (agent harness). Unlike
those three, `echo` is standalone — it does not talk to Harmony and runs on its own.

## Status: spec-only
