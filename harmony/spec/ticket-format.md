# Harmony — Ticket Format

Tickets live at `.score/tickets/<id>.yaml` inside each project repo. A ticket is a single
YAML file that grows progressively — fields are added as it advances through the workflow.
Fields not yet relevant are absent; Harmony ignores unknown fields.

All ticket files are git-tracked. Each status transition corresponds to a git commit.
Harmony commits machine-driven changes; human-driven changes may be committed directly or
proxied through Harmony's API (Aria → `ticket:update` → Harmony commits on the human's behalf).
Uncommitted file edits are invisible to Harmony — only committed state counts.

Schema version: `score.ticket/v1`

---

## Minimum (any state)

```yaml
schema: score.ticket/v1
id: fix-mode-feedback           # slug: [a-z0-9][a-z0-9-]*, unique per project
title: "Fix normal mode visual feedback"
status: pitched                 # see state-model.md for valid values
created: "2026-05-28"
```

Optional fields present from creation:

```yaml
notes: "indicator flickers on rapid switching — investigate debounce"
tags: [bug, macos]              # free-form strings; conventional tags below
assignee: "@builder"            # @me | @<role> | blank
pitch: >                        # Shape Up-style: problem + solution sketch
  The mode indicator flickers when switching faster than ~3/sec.
  A debounce in ModeManager should fix it.
appetite: small                 # small (~2h) | medium (~1d) | big (~3d) | blank
spawned_from: ~                 # ticket id that caused this one to be created
blocks: []                      # traceability only — no enforcement
blocked_by: []                  # HARD ENFORCED: ticket cannot enter ready until all are done
target:
  platform: any                 # any | macos | linux | android | ios | web
```

---

## Ready for execution

A ticket **cannot** enter `ready` status without a `spec` field. This is the only enforced
schema gate.

```yaml
# ... all fields above, plus:
status: ready
spec:
  what: >
    Debounce the mode state transition in ModeManager.
    Flicker occurs when switching >3 times per second.
  acceptance:
    automated:
      - "pnpm test"
      - "pnpm e2e mode-switching"
    manual:
      - "No visible flicker at 5+ mode switches per second"
      - "Mode indicator visible without obscuring primary content"
  constraints:
    - "Do not touch status bar layout"
  rework_notes: []              # appended by the human on each rework cycle (reviewing → ready)
  respec_notes: []              # appended by Harmony when a run returns infeasible (building → specced)
  clarifications: []            # Q&A from awaiting_input cycles; carried into the next run
```

`rework_notes`, `respec_notes`, and `clarifications` are all execution-history fields passed to
Voice as context on re-dispatch (see [`../../voice/spec/protocol.md`](../../voice/spec/protocol.md)).
A `clarifications` entry has the shape:

```yaml
clarifications:
  - run_id: "20260528-143012-a3f9"
    question: "Should the setting be a modal or an inline panel?"
    answer: "Inline panel."
    answered_at: "2026-05-28T15:10:00Z"
```

---

## During and after a run

Harmony writes these fields via git commit — do not edit manually while a run is in progress.

```yaml
status: building                # set when Harmony dispatches Voice
branch: "score/fix-mode-feedback"
started_at: "2026-05-28T14:03:00Z"

# After Voice exits 0 (completed):
status: reviewing
last_run_id: "20260528-143012-a3f9"

# After Voice exits 4 (needs-input) — run paused awaiting a human answer:
status: awaiting_input
last_run_id: "20260528-143012-a3f9"
spec:
  clarifications:
    - run_id: "20260528-143012-a3f9"
      question: "Should the setting be a modal or an inline panel?"
      answer: ~                 # human fills this in, then promotes back to ready

# After human approves:
status: done
completed_at: "2026-05-28T16:45:00Z"
```

---

## Rework

When the human rejects at `reviewing`:

```yaml
status: ready                   # reset — back into the dispatch queue
spec:
  rework_notes:
    - date: "2026-05-28"
      note: >
        Debounce works but the indicator still disappears for 100ms on fast switching.
        Add a minimum display duration of 150ms.
```

The full `rework_notes` history is visible in the ticket context passed to Voice.

---

## Respec (infeasible return)

When a run exits `infeasible`, Harmony moves the ticket back to `specced` and appends the
agent's analysis to `spec.respec_notes`:

```yaml
status: specced                 # back to shaping — the spec was not buildable as written
spec:
  respec_notes:
    - run_id: "20260528-143012-a3f9"
      date: "2026-05-28"
      reason: >
        ModeManager has no debounce hook to extend; the transition is driven by an OS-level
        event with no interception point. A 150ms minimum display can't be added without
        refactoring the event pipeline first.
      missing_prerequisites: ["refactor-mode-event-pipeline"]
```

The human re-shapes the spec (and optionally promotes any `missing_prerequisites` to real
tickets) before moving back to `ready`. Like `rework_notes`, the full `respec_notes` history is
passed to Voice on the next run.

---

## Conventional tags

| Tag | Meaning |
|-----|---------|
| `bug` | Something broken or regressing |
| `fr` | Feature request |
| `chore` | Deps, formatting, dead code |
| `refactor` | Restructure without behaviour change |
| `docs` | Documentation only |
| `macos` | macOS-specific |
| `linux` | Linux-specific |
| `hot-fix` | Needs to ship fast |
| `perf` | Performance work |

Any other string is valid. Tags are not enforced.

---

## Agent-created tickets

Agents (via Voice) may write new ticket YAML files to `.score/tickets/` and commit them.
Harmony accepts committed agent tickets **only if `status: pitched`**. Any commit introducing
a higher status is corrected by a Harmony counter-commit resetting to `pitched`, and a warning
is logged. Humans promote tickets; agents only discover them.
