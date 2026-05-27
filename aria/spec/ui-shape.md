# Aria — UI Shape

## Home: Kanban board

The default screen is a horizontal board with one column per ticket status:

```
 Pitched │ Specced │ Ready │ Building │ Reviewing │ Done
─────────┼─────────┼───────┼──────────┼───────────┼──────
 card    │ card    │ card  │ card ●   │ card      │ card
 card    │         │ card  │          │           │
         │         │       │          │           │
 [2/–]   │ [1/–]   │[2/4]  │  [1/4]   │  [1/2]    │
```

- WIP limit badge `[current/limit]` shown on capped columns.
- `●` on a Building card indicates a run is actively in progress.
- Cards show: title, assignee avatar/icon, age, tag pills.
- Clicking a card opens the ticket detail panel (slide-in or split).

## Ticket detail panel

Sections (all read from Harmony, none edited in-place except via explicit action):

1. **Header** — id, title, status badge, assignee picker, tags
2. **Spec** — rendered Markdown from `spec.what` and `spec.acceptance`
3. **Pitch** (if present) — appetite badge + pitch text
4. **Blockers** — `blocked_by` list with their current status
5. **Runs** — chronological list of past runs; click to open run report
6. **Actions** — context-sensitive buttons:
   - `Dispatch` (when status is `ready` and a CLI agent is available)
   - `Approve` / `Reject with notes` (when status is `reviewing`)
   - `Move to Ready` (when status is `specced` and spec field is present)
   - `Mark Blocked` / `Unblock` (always)

## Run-report panel

Opened from the Runs list in ticket detail. Renders the structured run report written by Voice.

Sections:
1. **Summary** — exit reason, CLI used, duration, token usage
2. **Files changed** — diff summary (file list + line counts)
3. **Acceptance checks** — each item in `spec.acceptance.automated` with pass/fail
4. **Evidence** — links to any files written to `.score/runs/<ticket-id>/<run-id>/`
5. **Agent notes** — free-text from the run report's `notes` field
6. **Raw log** (collapsed by default) — line-by-line Voice output stream

## Runtimes inventory panel

Accessible from a toolbar icon or menu. Shows detected CLI agents on this machine.

```
 Local Machine — Brian's MacBook Pro
 ─────────────────────────────────────────────────────
 ✓  claude           Claude Code 1.3.2    anthropic
 ✓  codex            OpenAI Codex CLI     openai
 ✗  gemini           not found            —
 ─────────────────────────────────────────────────────
 Harmony  localhost:4242  connected
```

Detection is done by Harmony (it probes `PATH`); Aria only renders the report.

## Assignee picker

Appears in the ticket detail header and the new-ticket form. Lists:

- `@me` — you, identified by `~/.score/config.yaml: operator`
- `@<agent>` — one entry per runtime detected by Harmony (e.g. `@claude`, `@codex`)

Selecting `@<agent>` and clicking Dispatch triggers `run:dispatch` to Harmony.
Selecting `@me` marks the ticket as human-assigned (no agent dispatch).

The picker grammar is uniform — adding a human team member later requires no UX change to
the picker; only Harmony's config gains a new entry.

## Navigation and layout

```
┌── Sidebar ─────────────────┬── Main content ──────────────────────────────┐
│  Projects                  │  Board  /  Ticket detail  /  Run report       │
│  > kaguya-browser  [hot]   │                                               │
│    aria            [warm]  │                                               │
│    harmony         [warm]  │                                               │
│                            │                                               │
│  ─────────────────         │                                               │
│  Runtimes inventory        │                                               │
│  ✓ claude  ✓ codex         │                                               │
│                            │                                               │
│  Harmony: connected        │                                               │
└────────────────────────────┴───────────────────────────────────────────────┘
```

Project mode badge (`[hot]`, `[warm]`, `[cold]`, `[frozen]`, `[maintenance]`) is coloured
but not interactive from the sidebar — mode changes go through the ticket board.
