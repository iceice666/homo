# Harmony — State Model

Harmony maintains **two separate state layers** for each ticket.

---

## Layer 1: Git-committed state (user-visible, durable)

Stored in the ticket YAML file's `status` field, committed to the project git repo. This is
what Aria displays and what the human operator reads and acts on. Git-committed state persists
across Harmony restarts — it lives in the repo, not in Harmony.

Each status transition corresponds to a git commit. Harmony commits machine-driven transitions
directly. Human-driven transitions come from the operator (via Aria → Harmony API → git, or
direct CLI commit); the git hook re-syncs the TicketCache either way.

```
pitched → specced → ready → building → reviewing → done
             ↑   ↑                │          │
             │   └────────────────┘          │   reviewing → ready  (rework: notes appended)
             │      infeasible               │   reviewing → specced (respec: spec re-shaped)
             │   (respec_notes appended)      │
             └────────────────────────────────┘
                     rework / respec
```

A `building` run can also park awaiting a human answer, then resume after the human answers:

```
building → awaiting_input → ready → building → …
              (questions written)   (answers in spec.clarifications)
```

Additional non-linear statuses:

```
any state → blocked         # human marks; no auto-transition out
blocked → ready             # human unblocks
any state → archived        # human retires a ticket permanently
```

### File state definitions

| Status | Owner | Entry condition | Meaning |
|--------|-------|-----------------|---------|
| `pitched` | human | created | Raw idea or agent-discovered prerequisite |
| `specced` | human | `spec` field present | Being shaped; spec written but not fully accepted |
| `ready` | human | `spec` present + no unresolved `blocked_by` | Queued for agent execution |
| `building` | Harmony | dispatched to Voice | Voice subprocess running |
| `reviewing` | human | Voice exited successfully | Run complete; awaiting human approve/rework/respec |
| `awaiting_input` | human | Voice exited `needs-input` | Run paused with questions; awaiting human answers, then re-dispatch |
| `done` | human | approved at `reviewing` | Accepted |
| `blocked` | human | manually set | Waiting on something outside the ticket system |
| `archived` | human | manually set | Permanently retired |

### Transition guards

- `pitched → specced` requires `spec` field present in the YAML.
- `specced → ready` (or `pitched → ready` directly) requires `spec` present + all `blocked_by` entries at `done`.
- `reviewing → ready` (rework): appends to `spec.rework_notes`; resets run fields. Use when the
  *execution* was wrong but the spec is sound.
- `reviewing → specced` (respec): the *spec itself* was wrong; the human re-shapes it before it
  can re-enter `ready`. Distinct from rework, which re-runs the same spec.
- `building → specced` (infeasible): set only by Harmony on Voice exit `3`; appends the agent's
  analysis to `spec.respec_notes`. The human then re-shapes and re-promotes to `ready`.
- `building → awaiting_input` (needs-input): set only by Harmony on Voice exit `4`; the pending
  `questions` are written and surfaced to Aria.
- `awaiting_input → ready`: requires every pending question answered; the human commits answers
  into `spec.clarifications`, which are carried into the next run's context.
- `* → building` is set only by Harmony's Dispatcher — Harmony commits this change. Never set by humans or agents directly.
- Agents may only write tickets with `status: pitched`. Any commit introducing a higher status is corrected by Harmony (a corrective commit resets to the last valid state).

### Cache recovery

On startup Harmony rebuilds its TicketCache entirely from git:

1. For each registered project, run `git show HEAD:.score/tickets/<id>.yaml` for all ticket files.
2. Load results into TicketCache.
3. For any ticket with `status: building`, transition to `ready` — Harmony commits this reset
   (message: `score: reset <id> building→ready on daemon restart`).
4. Recompute WIP counts and rebuild the dispatch queue from TicketCache.

Because all durable state lives in git, no state is lost across Harmony restarts.

---

## Layer 2: Run state (internal, ephemeral)

Held in Harmony's in-memory `Dispatcher` GenServer. Not persisted; not committed to git;
rebuilt on restart. Not visible in Aria. Drives the dispatch and retry logic.

```
Unclaimed → Claimed/Dispatching → Running → RetryQueued → Released
```

| Run state | Meaning |
|-----------|---------|
| `Unclaimed` | Ticket is `ready` but no Voice subprocess assigned yet |
| `Claimed/Dispatching` | Harmony has chosen this ticket and is setting up the workspace |
| `Running` | Voice subprocess is alive |
| `RetryQueued` | Voice exited non-zero; backoff timer set; will re-dispatch |
| `Released` | Voice exited 0 or terminal error; git-committed state updated; slot freed |

### Exit-code → run-state mapping

Only exit code `1` ever enters `RetryQueued`. Every other code releases the run with a single
committed file transition (see `lifecycle.md` and the canonical table in
[`../../CONTRACT.md`](../../CONTRACT.md)):

| Exit | `exit_reason` | Run-state outcome | File transition |
|------|---------------|-------------------|-----------------|
| `0` | `completed` | `Released` | `building → reviewing` |
| `1` | `failed` | `RetryQueued` → retry; on exhaustion `Released` | retries, then `building → blocked` |
| `2` | `hard-abort` | `Released` | `building → blocked` |
| `3` | `infeasible` | `Released` | `building → specced` (append `spec.respec_notes`) |
| `4` | `needs-input` | `Released` | `building → awaiting_input` (write `questions`) |
| `5` | `cancelled` | `Released` | `building → ready` (no retry) |

### Retry policy

- Exit code `1` (run failed): retry up to `max_retries` (config, default 2) with exponential
  backoff (base 30s, max 5m). After exhausting retries, Harmony commits `status: blocked` with
  an auto-appended note.
- Exit codes `2`, `3`, `4`, `5`: **no retry** — each releases the slot and commits its file
  transition immediately. Exit `5` (cancelled) is distinct from exit `1` (failed) specifically so
  a human `run:cancel` does not trigger a retry.
- Harmony restart: all `Running` run states evaporate; corresponding git-committed states reset
  from `building` to `ready` (Harmony commits the reset) and re-enter `Unclaimed`. Tickets already
  in human-pending states (`reviewing`, `awaiting_input`) are left untouched.

---

## WIP limits

Defined in `~/.score/config.yaml`. Harmony enforces before allowing transitions:

```yaml
wip_limits:
  building: 4          # max concurrent Voice subprocesses
  reviewing: 6         # soft cap — warns but does not block dispatch
  human_inbox: 3       # HARD CAP — blocks dispatch and ready-promotion when reached
```

`human_inbox` counts tickets awaiting a human action across all projects — both `reviewing`
(approve/rework/respec) and `awaiting_input` (answer questions). Both block the pipeline until
the human acts, so both apply backpressure. When the cap is reached:
- Harmony refuses new dispatches.
- Aria shows an inbox-full banner.
- The error message: "Inbox full: N/N tickets waiting for your decision. Clear them before
  dispatching new work."

### Worktree idempotency

Every dispatch — initial run, exit-`1` retry, or re-dispatch out of `awaiting_input`/`specced` —
gets a **fresh worktree reset to the base/default-branch tip**. Partial progress is never
preserved on-disk across dispatches; it is carried forward only through ticket context
(`spec.rework_notes`, `spec.respec_notes`, `spec.clarifications`). This makes every run start
from a defined state. Full setup/cleanup rules live in [`../../voice/spec/workspace.md`](../../voice/spec/workspace.md).

---

## Project modes

Each project has a mode field in `.score/config.yaml`:

| Mode | Dispatch allowed? | Meaning |
|------|-------------------|---------|
| `hot` | yes | Active focus project |
| `warm` | yes | Background progress OK |
| `cold` | no | Parked; no agent runs |
| `frozen` | no | Intentionally ignored |
| `maintenance` | hot-fix only | Low-risk upkeep only |

Tickets in `cold` or `frozen` projects remain in `ready` but are never dispatched.
