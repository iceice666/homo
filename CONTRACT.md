# Contract

This file is the canonical definition of the interfaces between `aria`, `harmony`, and `voice`.
Each package's spec docs link here rather than duplicating protocol details.

---

## Git as the canonical state store

All ticket YAML under `.score/tickets/` must be git-committed for state to be considered
durable. Harmony's in-memory `TicketCache` is a derived projection; any component that writes
ticket files (Harmony, Voice, future tooling) must commit those changes. State that exists
only on disk (uncommitted) is not considered part of the system state and is invisible to
Harmony.

Harmony installs `post-commit` and `post-merge` hooks in each registered project to receive
notifications when committed state changes. It reads ticket state from `git show HEAD:...`
rather than from the working tree directly.

---

## On-disk layout (per watched project)

Each project repository that Harmony watches gains a `.score/` directory:

```
<project>/
  .score/
    config.yaml            # project-level settings (WIP limits, assignees, …)
    tickets/
      <ticket-id>.yaml     # one file per ticket — the file state layer
    runs/
      <ticket-id>/
        <run-id>.json      # one run report per Voice invocation
    workspaces/            # git worktrees created by Voice
      <ticket-id>/         # worktree root — deleted after ticket reaches done/blocked
```

### Ticket file naming

`<ticket-id>` is a short, human-readable slug (`fix-mode-feedback`, `add-dark-theme`).
IDs must be unique within a project and match `[a-z0-9][a-z0-9-]*`.

### Run report naming

`<run-id>` is `<timestamp>-<short-random>` (e.g. `20260528-143012-a3f9`).

---

## Ticket YAML schema

Defined in full in [`harmony/spec/ticket-format.md`](harmony/spec/ticket-format.md).
Canonical schema version: `score.ticket/v1`.

Minimum required fields: `schema`, `id`, `title`, `status`, `created`.
A ticket cannot enter `ready` status without a `spec` field.

Valid `status` values: `pitched` · `specced` · `ready` · `building` · `reviewing` ·
`awaiting_input` · `done` · `blocked` · `archived`. `awaiting_input` is a human-pending state
(a run paused with questions); see [`harmony/spec/state-model.md`](harmony/spec/state-model.md).

---

## Harmony ↔ Aria protocol

Harmony exposes a **Phoenix Channels** endpoint (WebSocket-based) over a configurable local
port (default `4242`). Final wire format is deferred — see `aria/spec/protocol.md`.

The surface (channel events) that Aria uses:

| Direction | Event | Payload |
|-----------|-------|---------|
| Client→Server | `ticket:list` | `{ project_id }` |
| Client→Server | `ticket:create` | ticket partial YAML |
| Client→Server | `ticket:update` | `{ id, patch }` |
| Client→Server | `run:dispatch` | `{ ticket_id, cli }` |
| Client→Server | `run:cancel` | `{ run_id }` |
| Server→Client | `ticket:changed` | full ticket map |
| Server→Client | `run:started` | `{ run_id, ticket_id }` |
| Server→Client | `run:progress` | `{ run_id, line }` |
| Server→Client | `run:finished` | run report summary (includes `exit_reason`) |
| Server→Client | `run:needs_input` | `{ run_id, ticket_id, questions }` |

A run that ends `infeasible` rides on `run:finished` with `exit_reason: infeasible`. A run that
ends `needs-input` emits `run:needs_input` carrying the agent's questions. The human answers via
`ticket:update` — writing the answers into `spec.clarifications` and transitioning the ticket
`awaiting_input → ready`, which re-queues it for dispatch.

Aria must render an `awaiting_input` board column and flag infeasible-returned tickets (those
carrying `spec.respec_notes`) distinctly so they are not lost among hand-written `specced` drafts.

Authentication is local-only (shared secret in `~/.score/config.yaml`).
Multi-machine / team support is deferred.

---

## Harmony ↔ Voice spawn protocol

Harmony spawns Voice as a subprocess per ticket dispatch. Voice is **any binary or script**
that satisfies the following contract.

### Environment variables (set by Harmony)

| Var | Value |
|-----|-------|
| `VOICE_TICKET_PATH` | Absolute path to the ticket YAML file |
| `VOICE_WORKSPACE` | Absolute path to the git worktree for this ticket |
| `VOICE_CLI` | Adapter name: `claude` · `codex` · `gemini` · `cursor-agent` |
| `VOICE_REPORT_PATH` | Absolute path where Voice must write the run report JSON |
| `VOICE_RUN_ID` | Run ID string (for logging and report naming) |

### Voice exit codes

Each exit code maps to exactly one Harmony action and one user-visible ticket state.

| Code | `exit_reason` | Harmony action | Report | Worktree |
|------|---------------|----------------|--------|----------|
| `0` | `completed` | → `reviewing` | required | kept for inspection |
| `1` | `failed` | retry w/ backoff; then → `blocked` | partial (best-effort) | recreated fresh on retry |
| `2` | `hard-abort` | → `blocked`, no retry (workspace corrupt, CLI not found, etc.) | optional | removed |
| `3` | `infeasible` | → `specced`, no retry; append analysis to `spec.respec_notes` | **required** | kept for inspection |
| `4` | `needs-input` | → `awaiting_input`, no retry | **required** (carries `questions`) | kept for inspection |
| `5` | `cancelled` | → `ready` reset, no retry (response to `run:cancel` / SIGTERM) | partial (best-effort) | removed |

Codes `3`, `4`, `5` never retry. Cancellation has its own code so Harmony can distinguish a
human cancel from a genuine failure (both previously collided on exit `1`).

### Run report schema

Defined in full in [`voice/spec/report.md`](voice/spec/report.md).
Written as JSON to `VOICE_REPORT_PATH`. The report is **mandatory** for exit codes `0`, `3`,
and `4`; best-effort (partial) for `1` and `5`; optional for `2`.

`exit_reason` is one of: `completed` · `failed` · `hard-abort` · `infeasible` · `needs-input` ·
`cancelled`. A report with `exit_reason: needs-input` must carry a `questions` array; one with
`exit_reason: infeasible` must carry an `infeasibility` object.

Minimum fields: `run_id`, `ticket_id`, `cli`, `exit_reason`, `started_at`, `finished_at`.

### Worktree invariant

Every dispatch (initial run, retry, or re-dispatch after a human-pending state) gets a **fresh
worktree reset to the base/default-branch tip** — see [`voice/spec/workspace.md`](voice/spec/workspace.md).
Partial progress is not preserved on-disk across dispatches; it is carried forward only through
ticket context (`spec.rework_notes`, `spec.respec_notes`, `spec.clarifications`). Worktrees are
retained for human inspection while a ticket sits in a human-pending state (`reviewing`,
`awaiting_input`, or `specced` after an infeasible return) and removed on `done`, `blocked`, or
`hard-abort`.

---

## echo — standalone companion

`echo` is a personal conversational AI REPL (OCaml). It is **not** part of the Harmony/Aria/Voice
loop — it has no shared on-disk layout, no channel events, and is not dispatched by Harmony.

If echo is ever made Harmony-aware (e.g. injecting current-ticket context into its system
prompt), a new section must be added here before any code is written.

On-disk layout for echo is documented solely in `echo/spec/session.md`.

---

## Deferred decisions

The following are open and should be resolved in the spec file noted:

- Wire format: Phoenix Channels vs gRPC vs JSON-RPC → `aria/spec/protocol.md`
- Skill/role catalog shape after dropping pipeline/advisory split → `harmony/skills/README.md`
- macOS-vs-Linux desktop bootstrap order → `aria/spec/overview.md`
- Whether Harmony exposes a CLI client (fourth package or part of `harmony/`) → `harmony/spec/api.md`
- Whether echo gains Harmony awareness (ticket context injection) → `echo/spec/overview.md`
