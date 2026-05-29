# aria — Claude guidance

Desktop UI for the Partitura system. Aria is a thin viewer and driver over Harmony — all logic
lives in the state manager; Aria only displays state and forwards user intent. Two parallel
native implementations: SwiftUI on macOS, GTK 4 + Relm4 on Linux.

## Status: macOS scaffolded — Linux spec-only — no logic yet

`aria/macos/` is a Swift Package Manager skeleton (Swift 6, macOS 15+) with `AriaApp`,
`ContentView` (board columns), `Model` (MVU types), `HarmonyClient` (WebSocket stub), and
`Types/Ticket`. No logic; compiles cleanly.

`aria/linux/` is not yet scaffolded — bootstrap order is still deferred (see spec).

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

`aria/macos/` is scaffolded (SPM). `aria/linux/` is not yet scaffolded.

## Build (macOS)

```sh
# from aria/macos/
swift build
```

The root `.envrc` loads `.env` (gitignored, machine-local) after `use flake`, which sets
`DEVELOPER_DIR` and `SDKROOT` to the Xcode SDK. This overrides the Nix-provided macOS SDK
that `use flake` injects and is incompatible with the system Swift 6.x compiler.

## Key constraints

Aria is a **thin client**. It does not own state. If a behaviour requires persistent state
or business logic, it belongs in Harmony — Aria only renders what Harmony reports.

## Cross-package contract

See `../CONTRACT.md` for the Harmony↔Aria protocol surface. Update `CONTRACT.md` before
changing the protocol.
