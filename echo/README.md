# echo

The **unified LLM client** for the **Partitura** system, in Rust. One `Context` goes in, a
stream of typed events comes out — the same interface across every provider. Modelled on
[`@earendil-works/pi-ai`](https://www.npmjs.com/package/@earendil-works/pi-ai).

Delivered two ways from one codebase:

- a **library crate** that [`voice`](../voice/) links in-process for every model call, and
- a **thin CLI** for humans and non-Rust callers.

```sh
echo run  --model anthropic/claude-opus-4-8 < context.json   # one-shot: JSON in, JSONL events out
echo repl --model openai/gpt-…                               # interactive test REPL
```

## Providers (v1)

| Provider | Auth |
|----------|------|
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| OpenAI (ChatGPT subscription) | OAuth — `echo login openai-chatgpt` |

## What echo is not

Not an agent. No loop, no tools, no MCP, no persistence. It builds a request, sends it, and
surfaces the response. The agent loop is [`voice`](../voice/), which links echo.

## Docs

All design is in [`spec/`](spec/). The `voice`↔`echo` API is also in
[`../CONTRACT.md`](../CONTRACT.md). No implementation code exists yet (the spec describes the
Rust gateway; the current skeleton is the older OCaml scaffold, pending migration).

## Status: spec-only
