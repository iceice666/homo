# Voice — Failure & Compaction Contract

How the agent loop behaves when something other than clean completion happens: context
overflow, provider/MCP failure, budget exhaustion, cancellation. Defines what gets
**compacted** (continue the run), what gets **handed off** (carried to the next dispatch), and
how each terminal maps to an exit code. Companion to `agent-loop.md` (the loop), `protocol.md`
(exit codes), `report.md` (the report), and `workspace.md` (worktree cleanup). The exit-code →
ticket-transition mapping is canonical in [`../../CONTRACT.md`](../../CONTRACT.md).

## Why this exists

The happy path (`done(stop)` → acceptance → exit `0`) is the small, easy part. Agents fail
constantly — contexts overflow, providers 5xx, MCP servers die, humans cancel. How Voice
*fails* is what keeps Harmony's state machine coherent, since every exit code drives a ticket
transition. This file makes every non-happy branch explicit.

---

## One routine, two destinations

A single **summarize-state** operation produces a portable *digest* of the run — what's done,
current state, key decisions, what remains. It is used two ways:

- **Compact** — replace older messages with the digest and **continue the same run** (recover
  from context pressure).
- **Handoff** — write the digest into the run report so Harmony can carry it to the **next
  dispatch** (recover progress after a failure exit).

```
            summarize-state  →  digest
                   │
        ┌──────────┴───────────┐
        ▼                      ▼
   COMPACT (continue)     HANDOFF (exit)
   replace old msgs,      digest → report →
   keep system+ticket+    Harmony → spec.handoff_notes
   recent; loop resumes   → next dispatch reads it
```

### Digest mode — depends on what failed

| Mode | When | How |
|------|------|-----|
| **LLM** | the model/provider is reachable (overflow, MCP death, budget, cancel) | one `echo` call asks the model to summarize the run |
| **Mechanical** | the model/provider is the thing that failed | no model call: committed diff + turn count + last few messages |

Always attempt the LLM digest; fall back to mechanical if the provider is unreachable or the
summarize call itself errors.

### Invariants

- **Compact only at a completed turn boundary** — every `tool_call` must have its `ToolResult`.
  Compacting mid-turn leaves a dangling call that providers reject.
- A digest's summarize call **counts against `max_tokens`** like any other turn.
- The digest in the report is Voice's to write; **persisting it to the ticket
  (`spec.handoff_notes`) is Harmony's job** — Voice never mutates ticket YAML.
- Compaction preserves verbatim: the role `system_prompt`, the ticket request, and the most
  recent turns; it collapses older turns and large tool outputs.

---

## In-loop events — these continue the run (no exit)

| Trigger | When | Voice does | Result |
|---------|------|-----------|--------|
| Soft nudge | context ≈ 80%, after a turn | inject a synthetic message: "context ~80%; `compact` at a clean point" | agent *may* call `compact` |
| `compact` tool | agent-initiated — a **loop-control** built-in, distinct from the `infeasible` / `needs_input` **exit** built-ins | summarize-state → replace old messages with the digest | run continues, smaller context |
| Hard auto-compact | context ≈ 95%, or an `echo` `is_context_overflow` error | Voice compacts automatically (LLM digest, at a turn boundary) | run continues; if it **still** overflows → exit `1` |

The hard auto-compact is the safety net; the nudge + `compact` tool are a quality refinement
(the agent compacts at a natural boundary, where the summary is better). A nudge alone is not a
safety mechanism — overflow is a hard wall, so Voice must compact regardless of agent
cooperation.

---

## Terminal branches — the exit contract

Consistent with the exit-code table in `protocol.md` / `CONTRACT.md`; this adds the **handoff
digest** column and splits the `exit 1` row by cause.

| Trigger | Exit | `exit_reason` | Handoff digest | Report | Worktree | Harmony → ticket |
|---------|------|---------------|----------------|--------|----------|------------------|
| Agent `done(stop)` | `0` | completed | — (report `notes`) | required + acceptance results | kept | reviewing |
| Agent calls `infeasible` | `3` | infeasible | — (`infeasibility` object) | **required** | kept | specced (+ `respec_notes`) |
| Agent calls `needs_input` | `4` | needs-input | — (`questions` array) | **required** | kept | awaiting_input |
| MCP server death | `1` | failed | **LLM** | partial | removed | retry w/ backoff → blocked on exhaustion |
| Hard provider / `echo` error | `1` | failed | **mechanical** | partial | removed | retry → blocked |
| Overflow survived a compaction | `1` | failed | LLM (best-effort) | partial | removed | retry |
| Budget breach (`max_turns` / `max_tokens` / `max_seconds`) | `1` | failed | **LLM** | partial | removed | retry → *chunked progress* |
| `SIGTERM` (cancellation) | `5` | cancelled | — (human-initiated) | partial | removed | ready (reset) |
| Bad env / worktree setup failure | `2` | hard-abort | — (nothing to summarize) | optional | none / removed | blocked |

---

## Budget exhaustion becomes chunked progress

The fresh-worktree / no-resume invariant (`workspace.md`) means a plain retry redoes work from
scratch. The handoff digest changes that: a budget-exhausted run hands off, and the next
dispatch resumes the *knowledge* (files still reset to base, but the agent knows what was done).
This turns budget-retry from a waste loop into **chunked execution** — incremental progress
across dispatches, carried by `spec.handoff_notes` exactly as `rework_notes` / `clarifications`
already carry knowledge forward.

### Open item — convergence bound

Chunked progress needs a stop condition so it cannot run forever (each chunk costs tokens). The
existing failure-retry limit may be too low for "make progress over N chunks." **Unresolved:** a
max-dispatch count (or a human checkpoint) for handoff-driven retries. Tracked until decided.

---

## Impact on the contract

Two additions to settle in [`../../CONTRACT.md`](../../CONTRACT.md) before implementation:

- A `handoff` digest field in the run report (`score.run-report/v1`; see `report.md`).
- A carried-forward ticket field `spec.handoff_notes`, written by Harmony from the report and
  folded into the next dispatch's context (`agent-loop.md` context assembly).
