# Harmony — Ticket Lifecycle

Full reference for who can trigger each transition and what Harmony does on each one.

---

## Transition table

| From | To | Who | Guards | Harmony action |
|------|----|-----|--------|----------------|
| (new) | `pitched` | human or agent | id unique per project | Commits new file; logs creation |
| `pitched` | `specced` | human | `spec` field present | Human commits; hook re-syncs cache |
| `pitched` | `ready` | human | `spec` present + blockers resolved | Human commits; hook re-syncs; ticket enters dispatch queue |
| `specced` | `ready` | human | blockers resolved | Human commits; hook re-syncs; enters dispatch queue |
| `ready` | `building` | Harmony (dispatch) | WIP slot open; project mode allows; blockers done | Commits `status: building`, `started_at`, `branch`; spawns Voice subprocess |
| `building` | `reviewing` | Harmony (on Voice exit 0) | Voice wrote run report | Commits `status: reviewing`, `last_run_id`; notifies Aria |
| `building` | `blocked` | Harmony (on Voice exit 1, retries exhausted) | — | Commits `status: blocked` + auto error note |
| `building` | `blocked` | Harmony (on Voice exit 2, hard abort) | — | Commits `status: blocked` + error note; removes worktree |
| `building` | `specced` | Harmony (on Voice exit 3, infeasible) | report present with `infeasibility` | Commits `status: specced`; appends agent analysis to `spec.respec_notes`; notifies Aria; no retry |
| `building` | `awaiting_input` | Harmony (on Voice exit 4, needs-input) | report present with `questions` | Commits `status: awaiting_input`, `last_run_id`; writes pending questions; emits `run:needs_input`; no retry |
| `building` | `ready` | Harmony (on Voice exit 5, cancelled) | triggered by `run:cancel` | Commits `status: ready` reset; **no retry**; removes worktree |
| `building` | `ready` | Harmony (on restart) | Ticket was `building` at restart | Commits reset; re-queues |
| `reviewing` | `done` | human | — | Human commits; hook re-syncs; sets `completed_at` |
| `reviewing` | `ready` | human (rework) | — | Human commits with `rework_notes` appended; hook re-syncs; run fields reset |
| `reviewing` | `specced` | human (respec) | — | Human commits; spec re-shaped (the spec was wrong, not the execution); hook re-syncs |
| `awaiting_input` | `ready` | human (answers) | all `questions` answered | Human commits answers into `spec.clarifications`; hook re-syncs; enters dispatch queue |
| any | `blocked` | human | — | Human commits; hook re-syncs |
| `blocked` | `ready` | human | blockers resolved | Human commits; hook re-syncs; enters dispatch queue |
| any | `archived` | human | — | Human commits; hook re-syncs; removed from dispatch consideration |

Exit codes `3`/`4`/`5` never retry. `infeasible` routes back to `specced` so the human
re-shapes the spec rather than re-running it unchanged; `needs-input` parks the ticket in
`awaiting_input` until the human answers; `cancelled` is distinct from a failure (exit `1`) so a
human cancel does not trigger a retry. See `state-model.md` for the full exit-code → run-state
mapping and [`../../CONTRACT.md`](../../CONTRACT.md) for the canonical exit-code table.

---

## `blocked_by` enforcement

When `run:dispatch` is called:
1. Harmony reads the ticket's `blocked_by` list from TicketCache.
2. For each entry, checks that the referenced ticket has `status: done` in the cache.
3. If any are not `done`, the dispatch is rejected with a message listing the blockers and
   their current statuses.

`blocks` and `spawned_from` are informational only — no enforcement.

---

## Branch naming

When Harmony dispatches a ticket, it commits `branch: "score/<ticket-id>"` in the ticket file.
Voice creates the git worktree on this branch. Branch naming convention: `score/<id>`.

---

## Git hook events

Harmony installs two hooks in each registered project on first registration (or `harmony register`):

```sh
# .score/hooks/post-commit (installed by Harmony — do not remove)
#!/bin/sh
harmony notify --repo="$(pwd)" --commit="$(git rev-parse HEAD)"

# .score/hooks/post-merge (installed by Harmony — do not remove)
#!/bin/sh
harmony notify --repo="$(pwd)" --commit="$(git rev-parse HEAD)"
```

These call Harmony's local Unix socket endpoint. On receipt:

1. Identify changed ticket paths in the commit:
   `git diff-tree --name-only -r <sha>` filtered to `.score/tickets/`.
2. For each changed path, read from git: `git show <sha>:<path>`.
3. Run transition guards. If the commit came from outside Harmony and introduces an invalid
   state (e.g. an agent committed `status: building` directly), Harmony makes a corrective
   commit resetting to the last valid state and logs a warning. The hook from the corrective
   commit re-syncs the cache cleanly.
4. Update TicketCache.
5. Broadcast `ticket:changed` on the relevant Phoenix Channel.

Harmony also fires `post-commit` on its own commits; the receiver handles this idempotently
by comparing the committed state against the current TicketCache entry.

---

## Harmony restart recovery

On startup Harmony:
1. Reads all `~/.score/config.yaml` project entries.
2. For each project, reads all ticket files from git HEAD:
   `git show HEAD:.score/tickets/<id>.yaml` for each tracked ticket.
3. Loads ticket state into TicketCache.
4. Tickets with `status: building` are reset to `ready` — Harmony commits each reset
   (message: `score: reset <id> building→ready on daemon restart`). Their worktrees are
   orphaned and removed.
5. Human-pending states survive restart untouched: `reviewing` and `awaiting_input` tickets are
   left as-is (they await a human action, not a running process), and their worktrees are
   retained for inspection.
6. WIP counts (including the `human_inbox` cap) are recomputed from TicketCache.
7. Dispatch queue is rebuilt from `ready` tickets in priority order.
