# homo — repo guidance

Four independent packages. No monorepo manifest at the root.
Do not run build or test commands from here — cd into the relevant package first.

## Packages

- `aria/` — desktop UI (SwiftUI on macOS, GTK on Linux). See `aria/CLAUDE.md`.
- `harmony/` — Elixir/OTP state manager daemon. See `harmony/CLAUDE.md`.
- `voice/` — per-ticket agent harness (Rust). See `voice/CLAUDE.md`.
- `echo/` — personal conversational AI companion, readline REPL (OCaml). See `echo/CLAUDE.md`.

## Cross-package contract

The canonical interface between `aria`, `harmony`, and `voice` is `CONTRACT.md` (repo root).
If you change any wire format, on-disk layout, or spawn protocol in one package, update
`CONTRACT.md` first. (`echo` is standalone and is not covered by the contract.)

## Status

All packages are scaffolded with buildable skeletons. No business logic exists yet.
Implement specs module by module; update `CONTRACT.md` before changing any wire protocol.
