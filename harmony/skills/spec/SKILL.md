---
name: yjsp-spec
description: Write the execution spec for a yjsp ticket. Reads the ticket's notes, asks targeted questions, then writes the spec block directly into the ticket YAML file. Use when a ticket is in draft/backlog and needs a spec before it can be marked ready.
argument-hint: "<ticket-id>"
---

# yjsp-spec

Write a complete execution spec directly into a yjsp ticket file.

## Usage

```
/yjsp-spec <ticket-id>
```

## What This Does

Reads `.yjsp/tickets/<id>.yaml`, uses the `title` and `notes` to write the `spec:` block,
and saves it back. No separate document. No PRD. The output goes straight into the ticket.

## Workflow

### 1. Read the ticket

Load `.yjsp/tickets/<id>.yaml`. Extract `title`, `notes`, `project`, and any existing `spec:`.

If the ticket does not exist or has no `notes`, ask the user to describe what needs to be done
in 1–3 sentences before continuing.

### 2. Clarify only what is ambiguous

Ask at most 3 targeted questions — only what is genuinely unclear from the notes:

- What is the concrete observable outcome? (if notes are vague)
- What must not be broken? (constraints, if not obvious)
- Is this visual/interaction work requiring screenshots or video evidence?

Do not ask for user stories, success metrics, stakeholder impact, or business goals.
This is an implementation spec, not a PRD.

### 3. Write the spec block

Produce and write the following fields into the ticket YAML under `spec:`:

**`what`** — 2–4 sentences. What to implement and why it matters. Concrete enough that an
agent can start without asking questions. No vague directives like "improve the UX."

**`acceptance.automated`** — shell commands that must pass. Must be runnable as-is from the
project root. If you cannot derive real commands from the notes, ask. Do not invent fake ones.

Focus automated checks on: business-critical paths, error handling, edge cases, security
boundaries, data integrity. Skip: trivial getters/setters, framework internals, one-off scripts.

By component type:
- API / backend logic → unit tests for business logic, integration test for the HTTP layer
- Data / state → transformation correctness, idempotency, error paths
- Frontend / UI → interaction tests, visual regression if visual changes are involved
- Infrastructure → smoke test, not full chaos engineering

**`acceptance.manual`** — observable criteria, written as Given/When/Then or a plain checklist.
Each must be falsifiable: a machine or a clear manual step can mark it pass/fail.

Given/When/Then format:
```
- Given [precondition], when [action], then [specific observable outcome]
```

Checklist format (simpler for small tickets):
```
- [ ] <observable state that can be verified without judgment>
```

Rewrite any criterion that contains "looks good", "feels right", "is clean", "is fast",
"is intuitive" — those are not falsifiable. Example:
  ✗  "mode indicator looks good"
  ✓  "mode indicator is visible in all four corners of the viewport at 1280×800"

**`evidence_required`** — only if the ticket involves visual or interaction changes. Choose from:
`screenshot_matrix`, `key_sequence_replay`, `before_after_video`, `console_logs`, `test_output`,
`perf_trace`. Leave empty for pure logic/infra work.

**`constraints`** — hard limits the executor must not cross. At least one. Examples:
"do not change the public API", "must pass existing tests", "no new dependencies."

**`rework_notes`** — initialize as empty list `[]`.

### 4. Write directly to the file

Update the ticket YAML file in place. Do not print the YAML to the conversation — write it.
After writing, print a one-line confirmation:

```
✓ Spec written to .yjsp/tickets/fix-mode-feedback.yaml
  Next: review, then `yjsp promote fix-mode-feedback` to mark ready
```

If the current state is `backlog`, update it to `draft`. If already `draft` or higher, leave it.

## Output quality checklist (verify before writing)

- [ ] `what` is concrete enough to act on without follow-up questions
- [ ] every `acceptance.automated` command is a real, runnable shell command
- [ ] every `acceptance.manual` criterion is falsifiable (no "looks good")
- [ ] `evidence_required` is non-empty if `kind` would be visual-interaction
- [ ] at least one constraint exists
