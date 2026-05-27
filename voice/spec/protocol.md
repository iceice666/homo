# Voice — Protocol

How Harmony and Voice communicate.

---

## Spawn contract

Harmony spawns Voice as a child process. The full contract is defined in
[`../../CONTRACT.md`](../../CONTRACT.md). This file adds Voice-side implementation notes.

### Environment variables (set by Harmony)

| Var | Type | Description |
|-----|------|-------------|
| `VOICE_TICKET_PATH` | absolute path | Path to the ticket YAML file |
| `VOICE_WORKSPACE` | absolute path | Root of the git worktree Voice should create and work in |
| `VOICE_CLI` | string | Adapter name: `claude` · `codex` · `gemini` · `cursor-agent` |
| `VOICE_REPORT_PATH` | absolute path | Where Voice must write the run report JSON on exit |
| `VOICE_RUN_ID` | string | Run ID (`<timestamp>-<random>`) for logging and report naming |

Voice must validate all five vars on startup. If any is missing or invalid, exit `2`
(hard abort) immediately — workspace setup has not started yet so no cleanup is needed.

### Stdout

Voice should stream one line per unit of meaningful progress to stdout. Harmony relays these
as `run:progress` channel events to Aria (rate-limited to 10 Hz). Format is free-form text;
Harmony does not parse it. Prefix sensitive output with `[voice]` by convention.

### Exit codes

The canonical table lives in [`../../CONTRACT.md`](../../CONTRACT.md); it is mirrored here.

| Code | `exit_reason` | Harmony action | Report |
|------|---------------|----------------|--------|
| `0` | `completed` | Transition ticket to `reviewing` | required |
| `1` | `failed` | Schedule retry with backoff; → `blocked` on exhaustion | partial (best-effort) |
| `2` | `hard-abort` | Transition ticket to `blocked` (no retry) | optional |
| `3` | `infeasible` | Transition ticket to `specced`; append analysis to `spec.respec_notes` (no retry) | **required** |
| `4` | `needs-input` | Transition ticket to `awaiting_input`; surface `questions` (no retry) | **required** |
| `5` | `cancelled` | Reset ticket to `ready` (no retry) | partial (best-effort) |

Voice must always attempt to write a (possibly partial) run report before exiting `1` or `5`.
For exit `2` (missing env, workspace corruption, CLI not found), a report is optional. For exit
`3` and `4` the report is **mandatory** and must carry the `infeasibility` object / `questions`
array respectively (see `report.md`).

Cancellation has a dedicated code (`5`) so Harmony can tell a human `run:cancel` apart from a
genuine failure (`1`); the two must never share an exit code or the cancel would trigger a retry.

---

## Harmony → Voice: ticket context

Voice receives the ticket path via `VOICE_TICKET_PATH`. It should read the YAML and pass
the following fields to the CLI adapter as context:

- `spec.what` — the task description
- `spec.acceptance` — acceptance criteria
- `spec.constraints` — constraints
- `spec.rework_notes` — history of prior rework cycles (empty on first run)
- `spec.respec_notes` — history of prior infeasible returns (empty unless the spec was re-shaped)
- `spec.clarifications` — answered questions from prior `awaiting_input` cycles
- `pitch` — optional problem framing
- `notes` — optional free-form notes

The exact prompt assembly is adapter-specific (see `cli-adapters.md`). Voice does not build
the system prompt directly — that is the adapter's responsibility.

---

## Voice → human signaling (infeasible / needs-input)

The CLI agent has no direct channel to Harmony — it only writes files and exits. To return
`infeasible` (exit `3`) or `needs-input` (exit `4`), the agent signals Voice, which maps the
signal to the exit code and the corresponding run-report fields.

The signal mechanism is an adapter-spec decision (see `cli-adapters.md`); two viable forms:
- a reserved stdout marker line (e.g. `[voice:signal] {"kind":"needs-input", ...}`) that the
  adapter parses out of the stream, or
- a `signal.json` the agent writes into the workspace, which Voice reads after the CLI exits.

On receiving a signal Voice:
1. Stops treating the CLI's own exit code as authoritative.
2. Writes the mandatory run report — `infeasibility` for `infeasible`, `questions` for
   `needs-input`.
3. Exits `3` or `4` accordingly.

If no signal is present, Voice falls back to the normal completion/failure detection in
`cli-adapters.md`.

---

## Cancellation

Harmony sends `SIGTERM` to cancel a running Voice process. Voice should:
1. Catch `SIGTERM`.
2. Attempt to write a partial run report (`exit_reason: cancelled`).
3. Clean up the worktree if possible (best-effort; Harmony will clean up on next restart).
4. Exit `5` (cancelled). Do **not** exit `1` — that would schedule a retry of the cancelled run.
