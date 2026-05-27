# Harmony — Overview

## What Harmony is

Harmony is a local Elixir/OTP daemon that acts as the engine behind the homo system. It:

- Maintains a real-time **cache** of ticket state derived from each registered project's git repo.
- Enforces WIP limits and the two-layer state model (git-committed state + ephemeral run state).
- Dispatches Voice subprocesses against isolated git worktrees when a ticket is ready.
- Exposes a real-time API (Phoenix Channels) for Aria and future clients.

Harmony does not run models, call LLM APIs, or own any secrets. Agents come from external
CLIs (`claude`, `codex`, `gemini`, …) that Voice invokes.

## Guiding principles

1. **Git repo is the truth.** Committed ticket YAML in the project repo is the source of truth.
   Harmony's in-memory `TicketCache` is a derived projection of `git HEAD`. It can be wiped and
   rebuilt at any time with no data loss. Git push/pull is the sync mechanism.

2. **Harmony is a cache, not a state store.** Harmony holds no authoritative state. Every piece
   of state Harmony needs is either in committed git history or is ephemeral run state (Voice
   subprocess lifecycle — see `state-model.md`). If Harmony's cache and git disagree, git wins.

3. **Two-layer state model.** Committed ticket files carry the *git-committed state*
   (user-visible, durable). Harmony carries the *run state* (internal, ephemeral). Aria only
   sees git-committed state. See `state-model.md`.

4. **WIP limits as backpressure.** The pipeline can run faster than you can review.
   WIP limits on each column and a hard inbox cap prevent that from happening.
   See `swe-method.md`.

5. **Only you promote above `ready`.** Agents may write new tickets at `pitched` state.
   Only the human operator moves a ticket to `ready` (after writing a spec) or to `done`
   (after approving a review). A run executes unattended, but it may hand the ticket back to you
   asynchronously — `reviewing` (run complete), `awaiting_input` (needs an answer), or `specced`
   (the spec was infeasible). Re-dispatch carries your input forward. See `swe-method.md`.

6. **Lightweight.** Harmony is a local daemon, not a cloud service. No account, no signup.
   Configuration lives in `~/.score/config.yaml` and in the project's `.score/config.yaml`.

## OTP design intent

Each watched project is a supervised subtree:
- A `GitHookReceiver` GenServer listens for hook signals over a local Unix socket. When a
  `post-commit` or `post-merge` hook fires, it reads the changed ticket paths from the commit
  (`git diff-tree --name-only -r <sha>`), re-reads those files from git
  (`git show <sha>:<path>`), updates the TicketCache, and broadcasts events.
- A `Dispatcher` GenServer manages run state and owns the Voice subprocess pool.
- A `TicketCache` ETS table holds the current git-HEAD snapshot. It is a cache — not a store.

Harmony's top-level supervisor restarts any crashed subtree without affecting others.
Voice subprocesses are `Port`-linked to the Dispatcher — a crash signals the port, the
Dispatcher transitions the ticket back to `ready` (retry), commits the reset to git, and
schedules exponential backoff.

## Scope of v1

Must exist before shipping:

1. Git hook installer + receiver per project: installs `post-commit`/`post-merge` hooks in each
   registered project; receives signals over Unix socket; reads HEAD; updates TicketCache
2. State machine enforcer: guard transitions, enforce WIP limits
3. Dispatcher: spawn Voice per dispatch, relay output, write run report path; commit state
   changes to git for all machine-driven transitions
4. Phoenix Channels API: the surface defined in `api.md`
5. Config loader: `~/.score/config.yaml` + per-project `.score/config.yaml`

Out of scope for v1:

- Multi-machine routing (SSH dispatch)
- Team / multi-user presence
- CLI client (deferred — see `api.md`)
- Auto-dispatch on `ready` (v1 is manual-trigger only)
- Hook conflict resolution (if a project already has post-commit hooks, chaining is TBD)
