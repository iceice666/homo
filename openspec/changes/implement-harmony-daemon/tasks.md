## 1. Project scaffold & supervision skeleton

- [ ] 1.1 Create `harmony/mix.exs` as an OTP application with deps `phoenix`, `phoenix_pubsub`, a YAML parser (`yaml_elixir`), and `jason`; explicitly no `ecto`, `phoenix_html`, or `phoenix_live_view`
- [ ] 1.2 Add `Harmony.Application` with a top-level `one_for_one` supervisor over a `Registry`, the config store, the Phoenix `Endpoint`, the shared `GitHookReceiver`, and a `DynamicSupervisor` for project subtrees
- [ ] 1.3 Implement the per-project subtree supervisor that starts a `TicketCache` and a `Dispatcher` registered by `{project_id, role}` in the `Registry`, resolving each other by name (D2)
- [ ] 1.4 Add a project-registry/start path that brings up one subtree per registered project and tears one down cleanly; assert crash isolation between subtrees in a test

## 2. Configuration loading (harmony-config)

- [ ] 2.1 Load `~/.score/config.yaml`: `wip_limits.{building,reviewing,human_inbox}`, `api_token`, `max_retries`, `max_verify_cycles`
- [ ] 2.2 Load per-project `<project>/.score/config.yaml`: `mode`, `verify_loop`, project `max_verify_cycles` override, assignees
- [ ] 2.3 Implement precedence (explicit project > global > built-in default) and defaults (`max_retries`=2, `max_verify_cycles`=3, `verify_loop`=false)
- [ ] 2.4 Validate `mode` ∈ {hot, warm, cold, frozen, maintenance} and expose its dispatch-permission semantics
- [ ] 2.5 Tests for global/project precedence, defaults-when-absent, and mode validation

## 3. Git plumbing (harmony-git-integration — primitives)

- [ ] 3.1 Wrap `git show HEAD:<path>`, `git show <sha>:<path>`, and `git diff-tree --name-only -r <sha>` via `System.cmd`
- [ ] 3.2 Implement git-identity resolution: project `.git/config` → `~/.gitconfig` → `harmony` fallback
- [ ] 3.3 Implement field-preserving ticket writes: parse YAML → patch only managed fields → re-serialize → `git add` + `git commit` with `score: <id> …` messages
- [ ] 3.4 Add a per-project commit serialization point so Harmony-initiated commits never race (D5)
- [ ] 3.5 Tests: writes preserve `notes`/`pitch`/`tags`; commit messages and identity are correct

## 4. TicketCache (harmony-ticket-cache)

- [ ] 4.1 Implement the ETS-backed `TicketCache` built from `git show HEAD:.score/tickets/*.yaml`, rebuildable on init/crash with no data loss
- [ ] 4.2 Implement single-entry update from committed content (used by the hook flow)
- [ ] 4.3 Implement WIP counts, including the cross-project `human_inbox` (= `reviewing` + `awaiting_input`) folded across all caches
- [ ] 4.4 Implement the full per-project ticket snapshot served from ETS without git reads
- [ ] 4.5 Tests: rebuild-loses-nothing, cross-project `human_inbox` count, snapshot served without shelling to git

## 5. Hooks & sync flow (harmony-git-integration — receiver)

- [ ] 5.1 Implement `harmony register`: install `post-commit` and `post-merge` hooks calling `harmony notify --repo … --commit …`
- [ ] 5.2 Implement the `harmony notify` thin socket client and the `GitHookReceiver` Unix-socket listener (`~/.score/harmony.sock`, `chmod 600`), routing by repo via the `Registry` (D4)
- [ ] 5.3 Implement the sync flow: `diff-tree` filtered to `.score/tickets/` → `git show` each → guard → cache update → broadcast `ticket:changed`
- [ ] 5.4 Implement idempotent self-triggered-hook handling (committed == cache ⇒ no-op) and the one-step corrective reset for invalid external state (D6)
- [ ] 5.5 Tests: routing by repo; a Harmony commit's own hook no-ops; an agent commit above `pitched` is corrected in one step

## 6. State machine (harmony-state-machine)

- [ ] 6.1 Implement the transition-guard module: `ready` requires `spec`; `blocked_by` all `done` before dispatch; `building` Harmony-only; agent writes corrected to `pitched`
- [ ] 6.2 Implement WIP enforcement: hard `building` cap, hard `human_inbox` cap (with the canonical "Inbox full…" message), soft `reviewing` warn
- [ ] 6.3 Implement project-mode dispatch gating (cold/frozen never; maintenance hot-fix only)
- [ ] 6.4 Implement the Voice exit-code → file-transition mapping per `CONTRACT.md` (0→reviewing, 1→retry/blocked, 2→blocked, 3→specced+respec_notes, 4→awaiting_input+questions, 5→ready)
- [ ] 6.5 Implement the exit-`1`-only retry/backoff (base 30s, max 5m, `max_retries`) and the `awaiting_input → ready` "all questions answered" guard; reset run fields on rework
- [ ] 6.6 Tests: spec-gate, blocked_by rejection, inbox-cap message, exit-code branches, retry-then-block, cancel-no-retry

## 7. Dispatcher & Voice seam (harmony-dispatcher)

- [ ] 7.1 Implement `score.role-manifest/v1` resolution (global catalog + repo `.score/` overrides, repo wins) and write it to a file for `VOICE_ROLE_MANIFEST`
- [ ] 7.2 Build a **Voice stub** honouring the spawn contract (emits `score.voice-event/v1` lines, writes a `score.run-report/v1`, exits with a chosen code) for tests (D7)
- [ ] 7.3 Spawn one Voice per dispatch with the five `VOICE_*` env vars over a `Port` (`:exit_status`, line-buffered stdout); hold run state in the `Dispatcher`
- [ ] 7.4 Relay the stdout `score.voice-event/v1` stream as `run:progress` rate-limited to 10 Hz; log stderr only
- [ ] 7.5 Consume the run report on exit and drive `run:finished` (carrying `exit_reason`) plus the committed file transition
- [ ] 7.6 Implement worktree policy: base reset for independent dispatches; retain for human-pending states; remove on done/blocked/hard-abort; start the `appetite` soft timer
- [ ] 7.7 Implement `run:cancel` → `SIGTERM` → exit `5` → `ready` reset (no retry)
- [ ] 7.8 Tests (against the stub): every exit-code branch, the 10 Hz relay, env-var contract, base-reset-on-retry, cancel path

## 8. Verify loop (harmony-verify-loop)

- [ ] 8.1 Resolve opt-in (project `verify_loop` + per-ticket `verify` override, off by default); keep file state `building` for the whole loop
- [ ] 8.2 Implement the worktree carve-out: in-loop verifier and rework executor build on `score/<id>` at tip; independent dispatches still reset to base
- [ ] 8.3 Implement convergence: verifier `pass` → `building → reviewing`; verifier `fail` → append findings to `spec.rework_notes` (committed) → re-dispatch executor on tip
- [ ] 8.4 Enforce `max_verify_cycles` (default 3): surface to `reviewing` with outstanding findings on exhaustion; hold one `building` slot, runs sequential
- [ ] 8.5 Implement restart degradation (loop position not recovered; falls back to base + committed `rework_notes`) and route verifier `needs-input`/`infeasible` to `awaiting_input`/`specced`
- [ ] 8.6 Tests (against the stub): pass→reviewing, fail→re-dispatch, cycle-exhaustion, single-slot-sequential, restart-degradation

## 9. Phoenix Channels API (harmony-api)

- [ ] 9.1 Configure the `Endpoint` + `UserSocket` with `?token=<api_token>` auth (reject absent/mismatched)
- [ ] 9.2 Implement `projects:lobby`: `projects:list` reply (id, name, mode, status counts) and `project:changed` broadcast
- [ ] 9.3 Implement `project:<project_id>`: join snapshot + `ticket:list`; `ticket:create` and `ticket:update` (including the answer `awaiting_input → ready` and respec `reviewing → specced` paths)
- [ ] 9.4 Implement `run:dispatch` (`{ticket_id, role, model?}`) and `run:cancel`, wired to the dispatcher and guards
- [ ] 9.5 Emit outbound `run:started`/`run:progress`/`run:finished`/`run:needs_input`, `wip:warning`, and `inbox:blocked`
- [ ] 9.6 Tests: auth rejection, join snapshot, dispatch happy-path, needs-input surfacing, inbox:blocked at the hard cap

## 10. Restart recovery orchestration (harmony-supervision)

- [ ] 10.1 On project-subtree start, run recovery: rebuild cache from git HEAD; commit each `building → ready` reset and remove its orphaned worktree
- [ ] 10.2 Leave `reviewing`/`awaiting_input` untouched (worktrees retained); recompute WIP (incl. cross-project `human_inbox`); rebuild the dispatch queue from `ready` tickets
- [ ] 10.3 Tests: building-reset-on-restart commits the reset and re-queues; human-pending states and their worktrees survive untouched

## 11. End-to-end wiring & verification

- [ ] 11.1 Add an end-to-end test: Aria-client stub joins, dispatches, the Voice stub runs, the report drives the committed transition, and the client observes `run:*` events
- [ ] 11.2 Run `mix test` (and `mix format`/credo if configured) green from inside `harmony/`
- [ ] 11.3 Reconcile any spec drift discovered during implementation back into `harmony/spec/*` within this change; confirm `CONTRACT.md` needs no edits
- [ ] 11.4 Check off the two resolved `harmony/BACKLOG.md` items (`max_verify_cycles` default, verify-loop opt-in key); leave the Voice-side verifier-verdict mechanism open
- [ ] 11.5 Run `openspec validate implement-harmony-daemon --strict` and confirm it passes
