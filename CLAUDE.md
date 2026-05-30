# Partitura — repo guidance

Four independent packages. No monorepo manifest at the root.
Do not run build or test commands from here — cd into the relevant package first.

## Packages

- `aria/` — desktop UI (SwiftUI on macOS, GTK on Linux). See `aria/CLAUDE.md`.
- `harmony/` — Elixir/OTP state manager daemon. See `harmony/CLAUDE.md`.
- `voice/` — per-ticket agent harness (Rust): a native agent loop; one process per agent.
  Links `echo` in-process for model calls. See `voice/CLAUDE.md`.
- `echo/` — unified LLM client (Rust): a library crate (the LLM-request layer, à la `pi-ai`)
  plus a thin CLI with a test REPL. See `echo/CLAUDE.md`.

## Cross-package contract

The canonical interface between `aria`, `harmony`, `voice`, and the `echo` library is
`CONTRACT.md` (repo root). If you change any wire format, on-disk layout, spawn protocol, or
the `voice`↔`echo` API in one package, update `CONTRACT.md` first.

## Status

All packages are spec-only. No implementation code exists.
