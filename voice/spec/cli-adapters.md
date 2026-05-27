# Voice — CLI Adapters

A CLI adapter normalises a specific external CLI agent into the Voice protocol: how to invoke
it, how to parse its output, and how to detect completion vs. error.

---

## Adapter interface (conceptual)

Each adapter is responsible for:

1. **Locate** the CLI binary (check `PATH`; exit `2` if not found).
2. **Build the invocation** — command + flags + prompt from ticket context.
3. **Spawn** the process with the workspace as the working directory.
4. **Stream** output lines to Voice's stdout.
5. **Detect completion** — exit code, output pattern, or known error signal. Also detect the
   `infeasible` / `needs-input` signal the agent may emit (see "Agent signaling" below).
6. **Return** a result struct: `exit_reason` (`completed` · `failed` · `hard-abort` ·
   `infeasible` · `needs-input` · `cancelled`), `turns`, `token_usage` (if available), `notes`,
   and — when signaled — the `questions` / `infeasibility` payload.

---

## Supported adapters

### `claude` — Claude Code CLI

Binary: `claude` (Anthropic Claude Code)

Invocation pattern:

```sh
claude \
  --allowedTools "all" \
  --output-format stream-json \
  --print \
  "<prompt>"
```

Where `<prompt>` is assembled from the ticket's `spec.what`, acceptance criteria,
constraints, and `rework_notes`.

Completion detection: process exits. Exit code `0` = success. Any other code = failure.

Token usage: parse `stream-json` output for `usage` events if present.

### `codex` — OpenAI Codex CLI

Binary: `codex` (OpenAI Codex CLI)

Invocation pattern:

```sh
codex \
  --approval-policy auto-edit \
  --quiet \
  "<prompt>"
```

Completion detection: process exits.

### `gemini` — Google Gemini CLI

Binary: `gemini`

To be determined when the Gemini CLI stabilises. Placeholder — adapter not yet specified.

### `cursor-agent` — Cursor Agent

To be determined. Placeholder.

---

## Adding a new adapter

1. Add an entry to this file with the adapter's binary name, invocation pattern, and
   completion detection method.
2. Voice's adapter resolver maps `VOICE_CLI` strings to adapter definitions.
3. The adapter name becomes valid in `VOICE_CLI` once it is listed here and implemented.

---

## Prompt assembly

Each adapter builds a prompt from the ticket context. Suggested structure (adapters may
vary):

```
You are a coding agent working on a git worktree at <workspace path>.
Your task is to implement the following specification:

<spec.what>

Acceptance criteria:
<spec.acceptance.automated — one per line>
<spec.acceptance.manual — one per line>

Constraints:
<spec.constraints — one per line>

<if rework_notes present>
This is a rework. Prior feedback:
<spec.rework_notes — most recent last>
</if>

<if respec_notes present>
This spec was previously returned as infeasible and re-shaped. Prior analysis:
<spec.respec_notes — most recent last>
</if>

<if clarifications present>
Answers to earlier questions on this ticket:
<spec.clarifications — question/answer pairs>
</if>

Work autonomously. When done, ensure the acceptance criteria pass.

Do not guess your way past a wall:
- If the spec cannot be built as written, emit the `infeasible` signal with your reasoning
  instead of producing a broken result.
- If you need a human decision, a secret, or an out-of-band action to proceed, emit the
  `needs-input` signal with your question(s) instead of inventing an answer.
Otherwise, do not pepper the human with questions — proceed autonomously.
```

The final `<prompt>` string passed to the CLI is this assembled text.

---

## Agent signaling

An agent signals `infeasible` or `needs-input` to its adapter rather than exiting normally. The
adapter detects the signal (a reserved stdout marker line, or a `signal.json` the agent writes
into the workspace — see `protocol.md`), maps it to the matching `exit_reason`, and returns the
`infeasibility` object / `questions` array in its result struct. Voice then writes the mandatory
run report and exits `3` or `4`. Absent a signal, the adapter uses normal completion detection.

---

## CLI detection

On startup Voice should probe `PATH` for each known adapter binary. The runtimes list
returned to Harmony (via the run report's `detected_clis` field) is used by Aria to
populate the Runtimes Inventory panel and the assignee picker.
