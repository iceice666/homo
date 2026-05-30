# harmony — Claude guidance

Elixir/OTP git-native cache daemon for the Partitura system. Harmony maintains a real-time cache
of ticket state derived from each project's git repo, watches per-project `.score/` directories
via git hooks, enforces WIP limits, dispatches Voice subprocesses, and exposes a real-time
API to Aria.

## Status: spec-only

No Elixir source code exists yet. All design lives in `spec/`. Write spec before code.

## Spec map

| File | What it covers |
|------|----------------|
| `spec/overview.md` | Product goals, OTP design intent, guiding principles |
| `spec/ticket-format.md` | YAML schema `score.ticket/v1` — all fields, progression rules |
| `spec/state-model.md` | Two-layer state model: file state (user-visible) + run state (internal) |
| `spec/swe-method.md` | The "full house" workflow: Kanban + Shape Up + Spec-first + Just-enough |
| `spec/lifecycle.md` | Ticket state transitions, guards, who can trigger each move |
| `spec/verify-loop.md` | Optional automated executor↔verifier loop inside `building` |
| `spec/api.md` | The Phoenix Channels API surface exposed to Aria and future clients |

See also [`BACKLOG.md`](BACKLOG.md) — open questions and deferred work (plain checklist, not a spec).

## Roles & skills

An agent is a **role** (planner, builder, reviewer, …) — a setup, not an external CLI. Harmony
owns the **global** role catalog; a project's `.score/` provides repo-specific overrides (repo
wins). Skill prompts live in `skills/<name>/SKILL.md` and are one component of a role. At
dispatch Harmony resolves the role into a `score.role-manifest/v1` and passes its path to Voice
via `VOICE_ROLE_MANIFEST` (see `../CONTRACT.md` → "Role manifest"). Do not rename skill
directories — they are resolved by convention.

## Dev environment

Use the root `flake.nix` — enter with `nix develop .#harmony` (or `direnv allow`
from the repo root, then `nix develop .#harmony`).

Provides: `erlang`, `elixir`, `elixir-ls`. Mix/Hex caches go to `~/.mix`.

## Key constraints

- **Git is the only durable state.** The in-memory TicketCache is a derived projection that can
  be rebuilt at any time from `git HEAD`. Never treat the cache as authoritative.
- **Harmony runs no models and holds no API keys.** Agents run a native loop in Voice, which
  reaches models through `echo`; Harmony resolves roles, orchestrates dispatch, and enforces
  workflow rules.

## Cross-package contract

See `../CONTRACT.md` for the Harmony↔Aria protocol surface and the Harmony↔Voice spawn
protocol. Changes to either must be reflected in `CONTRACT.md` first.
