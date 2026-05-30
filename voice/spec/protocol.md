# Voice — Protocol

How Harmony and Voice communicate. The full contract is canonical in
[`../../CONTRACT.md`](../../CONTRACT.md); this file adds Voice-side implementation notes.

---

## Spawn contract

Harmony spawns Voice as a child process, one per agent, and manages it via an Elixir `Port`
(spawn + supervised stdout + exit signal + automatic teardown).

### Environment variables (set by Harmony)

| Var | Type | Description |
|-----|------|-------------|
| `VOICE_TICKET_PATH` | absolute path | Ticket YAML file (the request) |
| `VOICE_WORKSPACE` | absolute path | Git worktree root Voice creates and works in |
| `VOICE_ROLE_MANIFEST` | absolute path | Resolved `score.role-manifest/v1` JSON (see `roles.md`) |
| `VOICE_REPORT_PATH` | absolute path | Where Voice writes the run report on exit |
| `VOICE_RUN_ID` | string | Run ID (`<timestamp>-<random>`) for logging and report naming |

Voice validates all five on startup. If any is missing or invalid, exit `2` (hard abort)
immediately — worktree setup has not started, so no cleanup is needed. `VOICE_ROLE_MANIFEST`
replaces the former `VOICE_CLI`.

### Stdout — the progress stream

Stdout is a **protocol channel**, not logs: newline-delimited `score.voice-event/v1` JSON, one
event per line. Harmony tails it and relays each as a `run:progress` channel event (rate-limited
10 Hz). Event types: `turn` · `text` · `thinking` · `tool_call` · `tool_result` · `status` ·
`error`. **All human-facing logging goes to stderr.** Voice never writes free-form text to
stdout.

### Exit codes

Canonical table in [`../../CONTRACT.md`](../../CONTRACT.md); mirrored:

| Code | `exit_reason` | Harmony action | Report |
|------|---------------|----------------|--------|
| `0` | `completed` | → `reviewing` | required |
| `1` | `failed` | retry w/ backoff; → `blocked` on exhaustion | partial (best-effort) |
| `2` | `hard-abort` | → `blocked` (no retry) | optional |
| `3` | `infeasible` | → `specced`; append to `spec.respec_notes` (no retry) | **required** |
| `4` | `needs-input` | → `awaiting_input`; surface `questions` (no retry) | **required** |
| `5` | `cancelled` | reset → `ready` (no retry) | partial (best-effort) |

Voice always attempts a (possibly partial) report before exiting `1` or `5`. For `2` a report
is optional; for `3`/`4` it is mandatory and carries the `infeasibility` object / `questions`
array (`report.md`). Cancellation has a dedicated code so a human `run:cancel` is never
mistaken for a failure (which would retry).

---

## Harmony → Voice: ticket context

Voice reads `VOICE_TICKET_PATH` and folds these fields into the model context (see
`agent-loop.md` for assembly): `spec.what`, `spec.acceptance`, `spec.constraints`,
`spec.rework_notes`, `spec.respec_notes`, `spec.clarifications`, `pitch`, `notes`. Voice builds
the context directly (system prompt comes from the role manifest + repo `AGENTS.md`/`CLAUDE.md`,
not from an adapter).

---

## Voice → human signalling (infeasible / needs-input)

The agent signals a non-completion outcome by **calling a built-in tool**, not by exiting:

- `infeasible({ reason, missing_prerequisites?, suggested_spec_changes? })` → Voice writes the
  mandatory report (`infeasibility`) and exits `3`.
- `needs_input({ questions: [...] })` → Voice writes the mandatory report (`questions`) and
  exits `4`.

These built-ins are always present in the loop's tool set (`agent-loop.md`). This replaces the
old reserved-stdout-marker / `signal.json` scheme with a first-class, schema-validated handback.

---

## Cancellation

Harmony sends `SIGTERM`. Voice should:
1. Catch `SIGTERM` and stop the loop (abort the in-flight `echo` stream).
2. Tear down MCP servers.
3. Write a partial report (`exit_reason: cancelled`).
4. Best-effort clean the worktree (Harmony also cleans up on restart).
5. Exit `5` — **not** `1` (which would schedule a retry of a cancelled run).
