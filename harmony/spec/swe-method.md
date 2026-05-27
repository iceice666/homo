# Harmony — Workflow Method

The homo system blends four methods into one coherent flow. No single method is enforced in
full — each contributes one principle that fits solo-dev-with-agents work.

---

## The "full house" blend

### Kanban: board is home, pull is the move

- The default view (Aria's board) groups tickets by status column — that is the home screen,
  not a chat log or a sprint backlog.
- Work is pulled, not pushed. You move a ticket to `ready` when you're ready for it; Harmony
  dispatches when a WIP slot opens.
- WIP limits on `building` and `human_inbox` prevent the pipeline from filling faster than
  you can drain it.
- The board is always live — it reflects the current file state without a refresh.

### Shape Up: optional appetite bounds the build phase

- A ticket may include a `pitch` (problem framing + solution sketch) and an `appetite`
  (`small` ≈ 2h, `medium` ≈ 1d, `big` ≈ 3d).
- If `appetite` is set, Harmony starts a soft timer when the ticket enters `building`. When
  the appetite expires, Harmony surfaces a warning in Aria: "This run has exceeded its
  appetite." No hard stop — you decide whether to let it continue or intervene.
- Tickets without `pitch` or `appetite` are valid and common. Shape Up vocabulary is opt-in.

### Spec-first: the one enforced rule

- A ticket cannot enter `ready` without a `spec` field.
- This is the **only** hard schema gate in the system. Everything else is optional.
- The spec does not need to be elaborate — a two-sentence `what` and one acceptance criterion
  is enough. The requirement is that the agent has a written contract before it starts.
- The `specced` status exists for tickets whose spec is being written but is not yet accepted
  as execution-ready.

### Just-enough: everything else is optional

- `pitch`, `appetite`, `tags`, `assignee`, `blocked_by`, `blocks`, `spawned_from`,
  `target.platform` — all optional.
- The system does not enforce any of these beyond what is described above.
- Use the vocabulary that helps you on the ticket at hand; ignore the rest.

---

## How these interact in practice

A typical ticket journey:

1. **Idea captured** → `pitched`, just a title and maybe a note. Zero friction.
2. **You decide it's real** → write a `spec.what` and at least one acceptance criterion.
   Optionally add a `pitch` and `appetite` if the scope is uncertain.
   Move to `ready` (or `specced` if you want to keep shaping it).
3. **Harmony dispatches** → ticket moves to `building` when a WIP slot opens and you trigger
   dispatch (or auto-dispatch, if enabled). Voice sets up a worktree and runs the CLI agent.
4. **Agent finishes** → Voice writes a run report; ticket moves to `reviewing`.
   Aria surfaces the structured receipt.
5. **You review** → approve (→ `done`), rework (→ `ready` with notes appended, re-runs the same
   spec), or respec (→ `specced`, when the spec itself was wrong). The `human_inbox` cap ensures
   this step doesn't pile up.

Runs are **atomic** — there is no live pause/resume. But a run does not have to grind on or guess
when it hits a wall. Two clean early-exits hand the ticket back to you asynchronously, then
re-dispatch carrying the prior context forward (the same mechanism as `rework_notes`):

- **Infeasible** → the agent concludes the spec can't be built as written; the ticket returns to
  `specced` with the agent's analysis in `spec.respec_notes`. You re-shape, then re-promote.
- **Needs input** → the agent needs a decision, a secret, or an out-of-band action it cannot
  proceed without; the ticket parks in `awaiting_input` with its questions. You answer (written
  into `spec.clarifications`), and it re-enters the queue. Both states count toward `human_inbox`.

The human gate is therefore not *only* `reviewing` — these two hand-backs are additional,
asynchronous touchpoints. Runs still never block waiting on you live.

---

## Anti-patterns this design avoids

| Anti-pattern | How the blend prevents it |
|---|---|
| Inbox drowning | `human_inbox` hard cap; dispatch blocked when full |
| Vague agent runs | Spec required before `ready`; acceptance criteria in the contract |
| Agent guessing on ambiguity, or grinding on an impossible spec | `needs-input` parks for an answer; `infeasible` returns for a re-shape — neither wastes retries nor fabricates a decision |
| Scope creep mid-run | `appetite` timer surfaces overruns; you decide, not the system |
| Premature complexity | All Shape Up / dependency fields are opt-in |
| Chat-centric thinking | Board is home; agent conversations are a child of a ticket |
