# Aria — Overview

## What Aria is

Aria is the desktop front-end for the Partitura system. It gives you a visual, interactive view of
your project state: a Kanban board of tickets, ticket detail with spec and run history, a
run-report panel when an agent finishes, and a runtimes inventory showing which CLI agents are
available on this machine.

Aria does not own any state. It is a thin client that subscribes to Harmony, forwards user
actions, and renders what Harmony reports. Every meaningful action (move ticket, dispatch agent,
approve/reject) is a message sent to Harmony — Aria never writes ticket files directly.

## Guiding principles

- **Board is home.** The default view is a Kanban board, not a chat log. Agent conversations
  attach to tickets, not the other way around.
- **Thin client.** No local state beyond session preferences and Harmony connection config.
  Reload the app and everything is back because Harmony is the source of truth.
- **Agents are assignees.** From day one, the assignee picker lists `@me` and `@<agent-name>`
  uniformly. Adding a human collaborator later requires no UX change.
- **Lightweight and intuitive first.** Reach for the obvious interaction pattern before
  introducing a new concept.

## Platform strategy

Two parallel native codebases sharing only the protocol contract (see `../CONTRACT.md`):

| Platform | Toolkit | Target |
|----------|---------|--------|
| macOS | SwiftUI | macOS 15+ |
| Linux | GTK 4 | Gnome / typical distro |

Source directories (not yet scaffolded):

```
aria/
  macos/        # Xcode project, SwiftUI
  linux/        # Cargo project — Relm4 (gtk4-rs + Elm MVU)
  spec/         # this dir — shared design, no code
```

Cross-platform parity is achieved by keeping all non-UI logic in Harmony, not by sharing UI
code. Each impl is idiomatic for its platform.

Bootstrap order (deferred): decide whether to start macOS or Linux first when implementation
begins. Preference should reflect the primary daily-driver machine.

## Scope of v1

What must exist before shipping anything:

1. Harmony connection config + connect/reconnect UI
2. Board view: tickets grouped by status column, WIP count badges
3. Ticket detail: title, spec, current status, run history
4. Dispatch action: pick a CLI agent, trigger a run
5. Run-report panel: structured receipt after a Voice run finishes
6. Runtimes inventory: detected CLI agents on this machine
7. Human-action prompts: approve / reject at `reviewing` state

What is explicitly out of scope for v1:

- Multi-machine routing UI (deferred to when Harmony supports it)
- Team / multi-user presence
- In-app ticket creation beyond a minimal "new ticket" form
- Embedded chat / terminal
