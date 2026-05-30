# Voice — MCP ↔ echo Bridge

Voice owns all MCP knowledge; `echo` is MCP-agnostic. The bridge is **three translations**:
MCP tool schemas → `echo` `Tool`s, `echo` `ToolCall`s → MCP `tools/call`, MCP results → `echo`
`ToolResult`s. echo only ever sees its own types. Companion to `agent-loop.md` (the loop) and
`failure-contract.md` (what happens when a server dies or a result overflows).

```
        VOICE (owns MCP)                         echo (never sees MCP)
  tools/list  ──translate schema──▶  Tool[]      (Context.tools)
  tools/call  ◀──route by name───   ToolCall     (from toolcall_* events)
  CallResult  ──map content──────▶  ToolResult   (appended → next turn)
```

## v1 scope: tools only

MCP servers can offer **tools, resources, prompts, and sampling**. **v1 consumes tools only.**
Resources, prompts, and sampling are deferred (`../BACKLOG.md`). During `initialize` Voice
negotiates tool capability and ignores the rest.

---

## Server lifecycle

`mcp_servers` entries are `{ name, command, args, env }` → **stdio** servers (JSON-RPC over the
child's stdin/stdout). Voice is the client; use the `rmcp` SDK — do not hand-roll JSON-RPC.

```
per server:  spawn(command, args, env, cwd = VOICE_WORKSPACE)
             → initialize (protocol version, tool capability)
             → tools/list → translate to echo Tools
   ... run ...
             → on run end / Voice exit: shutdown + kill the process group
```

Discipline:

- **Pipes.** A server's stdout is its JSON-RPC channel to Voice; its stderr is its logs — drain
  them to **Voice's stderr**, never to Voice's stdout (the `voice-event` protocol channel).
- **Reaping.** Spawn in a process group and kill-on-drop, so a Voice crash never orphans a
  server.
- **cwd + env.** Servers run with `cwd = VOICE_WORKSPACE` (cwd-pin, `workspace.md`) and the
  manifest's per-server `env` (also how a server receives its own secrets).
- **Init failure.** If a server whose tools are in the role's `tools.allow` set fails to
  `initialize`, Voice exits `2` (hard-abort) — a broken environment, not the agent's fault. A
  failed server with no allowed tools is ignored.

---

## Tool enumeration & schema translation

Each MCP tool `{ name, description, inputSchema }` → `echo Tool { name: "<server>/<tool>",
description, parameters: inputSchema }`.

- **Namespacing.** `"<server>/<tool>"` prevents collisions across servers.
- **Reserved built-in names.** `needs_input`, `infeasible`, `compact` carry no `server/` prefix,
  so no MCP tool can shadow them.
- **`allow` gating, two layers.** Filter at enumeration (disallowed tools are never exposed)
  *and* reject an unknown/hallucinated tool name at call time with an `is_error` ToolResult.
  Never crash on a bad name.
- **Schema passthrough.** `inputSchema` (JSON Schema) goes to echo verbatim; provider-specific
  schema massaging (strict mode, etc.) is echo's job, not Voice's.

---

## The execution cycle

Tool calls are handled **as a batch on `done(tool_use)`**, never per streamed event — both
Anthropic and OpenAI emit multiple tool calls per turn.

```
on done(tool_use):
  1. append the assistant message (all N tool calls) to ctx.messages
  2. for each call, in emitted order:
       built-in?  → intercept (see "Built-ins")
       else       → tools/call on the owning server → map result
       emit tool_call + tool_result voice-events
  3. append N ToolResults — EVERY tool_call_id answered (all-or-nothing)
  4. loop back to echo::stream
```

- **All-or-nothing.** An assistant message with N tool calls must be followed by N tool results
  (every id answered), or the next provider request is rejected for a dangling call. A tool that
  *fails* still yields a result with `is_error = true`. A tool whose *server is dead* is the
  MCP-death branch → exit `1` + handoff (`failure-contract.md`).
- **Sequential execution (v1).** Execute the N calls one at a time, in emitted order. One
  worktree means concurrent writes race; determinism outweighs the latency. Parallelism gated on
  MCP `readOnlyHint` annotations is a v2 lever (`../BACKLOG.md`).

---

## Content mapping (MCP result → echo `ToolResult`)

echo's `ToolResult` content is `(Text | Image)[]`; several MCP content types must be projected:

| MCP content item | → echo `ToolResult` content |
|------------------|-----------------------------|
| `text` | `Text` |
| `image` { data, mimeType } | `Image` (bytes) |
| `audio` { data, mimeType } | `Text` placeholder ("[audio omitted]") — echo has no audio block |
| `resource`, embedded text | `Text` |
| `resource`, embedded blob (image mime) | `Image` |
| `resource`, embedded blob (other) | `Text` note (uri + "[binary omitted]") |
| `resource_link` { uri } | `Text` note (the uri) |
| `structuredContent` (JSON) | `Text` (JSON-encoded) |
| `isError: true` | → `ToolResult.is_error = true` |

**Size policy.** Cap tool-result size and truncate with a "[truncated N bytes]" marker — the
same lever compaction uses (`failure-contract.md`). Exact cap value: TBD (`../BACKLOG.md`).

**Per-call timeout.** A tool that does not return within the timeout yields an `is_error`
ToolResult ("tool timed out") and the loop continues — distinct from server death.

---

## Built-ins

Three built-ins live in the tool set but are intercepted, never routed to MCP. Two categories:

- **Exit signals:** `infeasible`, `needs_input` → stop the loop, write the report, exit `3`/`4`.
- **Loop control:** `compact` → summarize-state, continue (`failure-contract.md`).

Mixed-turn ordering (a built-in called alongside regular tools in one turn):

- `compact` + regular tools → run the regular tools, append results, *then* compact (the digest
  subsumes the completed turn; the `compact` call vanishes into the new history). Continue.
- `infeasible` / `needs_input` + regular tools → the exit signal wins: stop immediately, do not
  run the siblings (no next request, so dangling calls are moot).

---

## Decisions (v1)

| Decision | Call |
|----------|------|
| MCP capabilities consumed | tools only (resources / prompts / sampling → v2) |
| N tool calls per turn | execute all, sequentially, in emitted order |
| Tool-result size | cap + truncate with marker |
| Per-call timeout | `is_error` result, continue |
| Server fails `initialize` (tools in `allow`) | exit `2` (hard-abort) |
| `allow` gating | at enumeration + call-time reject |
| MCP client | `rmcp` (official SDK) |
