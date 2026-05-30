# Voice — Agent loop

Voice is the **agent basement**: one native agent loop per process. It does not wrap an
external agent CLI — it drives the model itself through the linked `echo` library and executes
tools (from MCP) on the model's behalf.

A *role* (see `roles.md`) parameterises the loop; the loop itself is the same for every role.

---

## The loop

```
1. Assemble Context        (system_prompt + skill + repo AGENTS.md/CLAUDE.md + ticket request;
                            tools = built-ins + MCP tools)
2. echo::stream(model, ctx)
3. For each streamed event:
     text / thinking  → emit score.voice-event/v1 to stdout
     tool_call deltas → emit + accumulate (do not execute yet)
4. On the terminal event:
     done(stop)       → finalise: run acceptance checks, write report, exit 0
     done(tool_use)   → execute ALL N tool calls (see mcp-bridge.md), append the assistant
                        message + N ToolResults, go to 2
     built-in signal  → write report, exit 3 (infeasible) / 4 (needs-input)
     error / overflow / budget → see failure-contract.md
```

Voice links `echo` as a crate, so step 2 reuses one connection across turns and shares types
with no serialisation. See `echo/spec/api.md` for `Context`/event shapes.

---

## Context assembly

Voice builds the `echo::Context` for each turn from:

- `system_prompt` and `skill.body` — from the role manifest (`roles.md`).
- The repo's root `AGENTS.md` / `CLAUDE.md` — read from `VOICE_WORKSPACE`.
- The **ticket request** — `spec.what`, `spec.acceptance`, `spec.constraints`,
  `spec.rework_notes`, `spec.respec_notes`, `spec.clarifications`, plus `pitch` / `notes`
  (read from `VOICE_TICKET_PATH`; same fields as the old protocol).
- The growing `messages` list (prior turns + tool results) for this run.

System content order: base `system_prompt` → repo `AGENTS.md`/`CLAUDE.md` → `skill.body` →
the **Voice harness addendum** (the built-in / commit / stop / budget protocol, injected last for
salience — see `system-prompt.md`). The ticket request is the first user message.

---

## Tools

Two sources, both surfaced to the model as `echo` `Tool` schemas:

1. **MCP tools.** Voice launches the role's `mcp_servers` (`roles.md`), enumerates their tools,
   and converts each to a `Tool` (name `"<server>/<tool>"`, JSON-Schema params). On
   `done(tool_use)` Voice routes each call to the owning MCP server and returns its result as a
   `ToolResult`. **echo never sees MCP** — it only sees schemas and emits calls. v1 consumes MCP
   **tools only** (resources/prompts/sampling are v2). Full bridge mechanics — lifecycle, batch
   execution, content mapping — are in `mcp-bridge.md`.
2. **Built-in tools** (always present), two kinds: **exit signals** `needs_input` / `infeasible`
   (below) and **loop control** `compact` (`failure-contract.md`).

The role's `tools.allow` list gates which tools are exposed (at enumeration, plus a call-time
reject for unknown names).

---

## Built-in signals: infeasible / needs-input

The agent does not exit by itself — it *calls a tool* to signal a non-completion outcome.
Voice intercepts these built-ins instead of forwarding them to MCP:

- `infeasible({ reason, missing_prerequisites?, suggested_spec_changes? })` → Voice stops the
  loop, writes the mandatory report with an `infeasibility` object, exits `3`.
- `needs_input({ questions: [{ id, prompt, kind, options? }] })` → Voice stops the loop, writes
  the mandatory report with a `questions` array, exits `4`.

This replaces the old "reserved stdout marker / `signal.json`" mechanism — the model has a
first-class, schema-validated way to hand back. The system prompt instructs the agent to call
these rather than guess past a wall, and otherwise to proceed autonomously. See `report.md` for
the payloads.

---

## Completion & acceptance

On `done(stop)` Voice runs `spec.acceptance.automated` commands in the workspace, records results
in the report, and exits `0`. This is the **mechanical** acceptance layer — cheap, deterministic,
and trustworthy, but not a hard gate that flips the exit code in v1.

Deeper review — whether the change actually satisfies the spec, including what the commands miss
— is a separate **judgment** layer, done by a verifier role and/or a human (see "Skills, not
pipelines" in `roles.md`). The two layers compose; a verifier does not replace mechanical
acceptance.

---

## Budgets

The role manifest's `budgets` (`max_turns`, `max_tokens`, `max_seconds`) bound the loop. On
breach Voice writes a partial report and exits `1` (failed → retry per `CONTRACT.md`). Token
usage comes from `echo`'s per-response `Usage`.

---

## Output discipline

- **stdout** = `score.voice-event/v1` JSONL only (the progress stream; see `protocol.md`).
- **stderr** = human-facing logs.
- Voice never writes free-form text to stdout — Harmony parses it.
