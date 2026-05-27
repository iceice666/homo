# aria — Claude guidance

Desktop UI for the homo system. Aria is a thin viewer and driver over Harmony — all logic
lives in the state manager; Aria only displays state and forwards user intent. Two parallel
native implementations: SwiftUI on macOS, GTK 4 + Relm4 on Linux.

## Status: spec-only

No implementation code exists yet. All design lives in `spec/`. Write spec before code.

## Spec map

| File | What it covers |
|------|----------------|
| `spec/overview.md` | Product goals, platform strategy, guiding principles |
| `spec/ui-shape.md` | Screen layout, board model, panels, interaction grammar |
| `spec/protocol.md` | How Aria talks to Harmony (events, wire format options) |
| `spec/linux-stack.md` | Linux GUI stack decision: GTK 4 + Relm4 (Elm MVU in Rust) |
| `spec/app-flow.md` | Framework-agnostic MVU model, messages, update, startup sequence |

## Package layout (planned)

Two parallel codebases sharing only the protocol contract (see `../CONTRACT.md`) — no UI code
is shared. Cross-platform parity comes from keeping all non-UI logic in Harmony.

```
aria/
  macos/    # Xcode project — SwiftUI, native macOS (target macOS 15+)
  linux/    # Cargo project — GTK 4 + Relm4 (Elm MVU in Rust)
  spec/     # shared design — no code
```

Neither codebase is scaffolded yet. Finalise the spec before starting either; bootstrap order
(macOS vs Linux first) is deferred.

## Key constraints

Aria is a **thin client**. It does not own state. If a behaviour requires persistent state
or business logic, it belongs in Harmony — Aria only renders what Harmony reports.

## Cross-package contract

See `../CONTRACT.md` for the Harmony↔Aria protocol surface. Update `CONTRACT.md` before
changing the protocol.
