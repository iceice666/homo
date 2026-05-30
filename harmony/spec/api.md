# Harmony — API

The public surface Harmony exposes to Aria and future clients.

---

## Phoenix Channels (recommended v1 transport)

See [`../../CONTRACT.md`](../../CONTRACT.md) for the canonical event list and payload shapes.
This file documents Harmony-side semantics for each event.

### Channel: `projects:lobby`

Join to get the project list and connection health.

| Event (inbound) | Behaviour |
|-----------------|-----------|
| `projects:list` | Reply with list of registered projects: id, name, mode, ticket counts by status |

| Event (outbound) | Trigger |
|------------------|---------|
| `project:changed` | Project mode or config changed |

### Channel: `project:<project_id>`

Join to subscribe to a specific project's tickets and runs.

On join: reply with full ticket snapshot (all tickets for that project).

| Event (inbound) | Behaviour |
|-----------------|-----------|
| `ticket:list` | Re-send full snapshot from TicketCache |
| `ticket:create` | Validate + write new ticket YAML; commit to git; broadcast `ticket:changed` |
| `ticket:update` | Validate patch + transition guards; write YAML; commit to git on behalf of the human operator; broadcast `ticket:changed`. Also the path for answering a paused run (write `spec.clarifications`, transition `awaiting_input → ready`) and for respec (`reviewing → specced`). |
| `run:dispatch` | Validate guards; resolve the role manifest (global + repo overrides) and write it to `VOICE_ROLE_MANIFEST`; commit `status: building` to git; spawn one Voice subprocess. Payload `{ ticket_id, role, model? }` |
| `run:cancel` | Send SIGTERM to Voice subprocess. Voice exits `5` (`cancelled`); Harmony commits `status: ready` reset. **No retry** — exit `5` is distinct from exit `1` (failed) precisely so a cancel does not re-dispatch. |

| Event (outbound) | Trigger |
|------------------|---------|
| `ticket:changed` | Any ticket file write |
| `run:started` | Voice spawned |
| `run:progress` | A `score.voice-event/v1` event from Voice's stdout stream (rate-limited 10 Hz) |
| `run:finished` | Voice exited; payload: run report summary (includes `exit_reason`). An `infeasible` return rides on this event with `exit_reason: infeasible`; Aria reads `spec.respec_notes` for the analysis. |
| `run:needs_input` | Voice exited `needs-input` (exit `4`); payload: `{ run_id, ticket_id, questions }`. Aria prompts the human; answers return via `ticket:update`. |
| `wip:warning` | A soft WIP cap exceeded |
| `inbox:blocked` | Hard inbox cap reached (counts `reviewing` + `awaiting_input`) |

### Authentication

Local-only: shared secret from `~/.score/config.yaml: api_token` passed as `?token=<secret>`
query parameter on WebSocket connect. Multi-machine / team auth is deferred.

### Git integration

Harmony requires write access to each registered project's git repo. All state-changing
operations that Harmony initiates (dispatching, transition commits, corrective resets) are
committed using the git identity from the project's `.git/config`, falling back to
`~/.gitconfig`. Commit messages follow the convention `score: <id> <from>→<to>` for
machine-driven transitions and `score: <id> <action>` for administrative operations (e.g.
`score: reset abc building→ready on daemon restart`).

---

## Deferred: CLI client

A `harmony` or `score` CLI that talks to the API over the same Phoenix Channels socket would
allow headless operation (SSH, CI). This is not in scope for v1.

Options when implementing:

1. **Separate package** — a fourth package in the repo (`cli/` or `score-cli/`).
2. **Mix escripts inside harmony/** — a Mix escript target in the Harmony package.

The API surface is already sufficient for a CLI client; the decision is packaging only.

---

## Deferred: gRPC / JSON-RPC alternative

If Phoenix Channels proves inconvenient for the GTK client or a future non-Elixir client,
the alternative is JSON-RPC 2.0 over WebSocket (simpler, no Phoenix dep in clients) or gRPC
(strong typing, better for multi-machine). Resolve before writing the GTK client.
