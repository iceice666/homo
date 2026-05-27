---
name: yjsp-triage
description: Decide which draft/backlog tickets to promote to ready given current WIP, project modes, and your available time. Use at the start of a work session or week to choose what to send to agents next.
argument-hint: "[available time, e.g. '3 hours' or 'today']"
---

# yjsp-triage

Decide what to promote to `ready` right now, given the full state of your pipeline.

## Usage

```
/yjsp-triage [available time]
```

## What This Does

Reads all project states and ticket states, checks WIP limits and inbox count, and gives you
a short prioritized list of tickets to promote — or tells you to clear your inbox first.

## Workflow

### 1. Read current state

Load `~/.yjsp/config.yaml` for WIP limits and project registry.
For each project, read `.yjsp/project.yaml` (mode, priority) and all ticket files.

Build a summary:
- Inbox count (`need-human` tickets) vs `human_inbox` limit
- `building` count vs `wip_limits.building`
- `verifying` count vs `wip_limits.verifying`
- `hot` project count vs `wip_limits.hot_projects`

### 2. Check the inbox first

If `need-human` count ≥ `human_inbox` limit:

```
✗ Inbox full (3/3). You cannot promote new tickets until you clear your inbox.

Inbox tickets:
  1. fix-mode-feedback (kaguya-browser) — waiting since 2d ago
  2. stabilize-candidate-bar (android-ime) — waiting since 1d ago
  3. e2e-permission-restore (drive-system) — waiting since 3h ago

Run `yjsp list --inbox` to review them.
```

Stop here. Do not suggest promotions until the inbox is drained.

### 3. Assess available capacity

If the user provided a time budget, use it. Otherwise ask: "How much time do you have today?"

Map time to realistic ticket capacity:
- < 1 hour: promote at most 1 ticket, pick smallest scope
- 1–3 hours: promote 1–2 tickets
- half day+: promote up to `wip_limits.building` minus current `building` count

### 4. Rank candidates

From tickets in `draft` state with complete specs (has `spec.what` filled), across `hot` and
`warm` projects only. Skip `cold`/`frozen` projects.

Note which machine is running the triage. Tickets with `target.platform` that doesn't match
the current machine are shown separately as `[remote]` — runnable via SSH but not locally.
Include them in the list; mark them clearly.

Rank by:
1. Project priority (P0 > P1 > P2 > P3)
2. Project mode (`hot` before `warm`)
3. Blocked-by resolved (all `blocked_by` tickets are `done`)
4. Rework tickets first (has `spec.rework_notes`) — they are almost done
5. Smaller scope (`acceptance.automated` count as proxy)

Flag any ticket where `spec:` is missing or incomplete — suggest running `/yjsp-spec` on it
before promoting.

### 5. Output the recommendation

```
Triage — 2026-05-27 | Inbox: 0/3 · Building: 1/4 · Available today: ~2 hours

Promote these:
  1. fix-mode-feedback (kaguya-browser, P1, hot) — rework cycle, nearly done
     → yjsp promote fix-mode-feedback

  2. stabilize-candidate-bar (android-ime, P2, warm) — clean spec, low risk
     → yjsp promote stabilize-candidate-bar

Hold:
  - add-dark-mode — blocked by add-theme-switch-system (backlog, not specced)
  - refactor-logging — project is cold

Not ready (needs spec):
  - keyboard-shortcuts-rework — no spec.what yet → /yjsp-spec keyboard-shortcuts-rework
```

Keep it short. This should take under 60 seconds to read and act on.
