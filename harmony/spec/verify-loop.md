# Harmony — Verify Loop

An optional automated **executor ↔ verifier** loop that runs inside `building`, before a ticket
surfaces to the human at `reviewing`. The executor builds; a verifier role independently checks
the work; on failure its findings re-dispatch the executor; the loop spins until the verifier
passes or a cycle bound is hit. Only converged (or stuck) work reaches the human — reducing
`human_inbox` pressure.

The loop lives **in Harmony**: one agent per Voice process forbids an internal pipeline (see
[`../../voice/spec/roles.md`](../../voice/spec/roles.md)). It is run-state orchestration of an
already human-triggered dispatch, not auto-start of work.

## Scope

- **In v1.** The loop runs once a human triggers a dispatch.
- **Distinct from the deferred auto-dispatch.** `ready → building` stays human-triggered in v1
  (`overview.md`). The verify loop does not auto-*start* work — it orchestrates a run the human
  already started. The two are orthogonal.
- **Opt-in.** Enabled per project (`.score/config.yaml`) and overridable per ticket; off by
  default. When off, `building → reviewing` on executor exit `0` is the direct human-review path,
  unchanged.

## The loop

The file state stays `building` for the whole loop; the executor/verifier ping-pong is **run
state** (Layer 2, `state-model.md`), invisible in Aria except through the live per-run progress
stream. The human sees one `building` phase, then `reviewing`.

```
 ready ─(human dispatch)→ building ──────────────────────────────────────── file state
                             │
   ┌──── run-state loop (file stays building) ───────────────────────────────┐
   │  1. executor run   →  commits to score/<id>                              │
   │  2. verifier run   →  reads score/<id> @ tip   ◀── worktree carve-out     │
   │        verdict?                                                          │
   │         ├ pass ──────────────────────────▶ building → reviewing (human)  │
   │         └ fail → findings → spec.rework_notes (commit)                   │
   │                  re-dispatch executor on score/<id> @ tip ───────────────┘
   │                  (cycle++)
   └─ cycle == max_verify_cycles ─▶ building → reviewing (carrying findings)
```

### Two layers compose

Mechanical acceptance and verifier judgment are different layers, not alternatives:

- **Mechanical acceptance** — the executor run runs `spec.acceptance.automated` and records
  results in its report ([`../../voice/spec/agent-loop.md`](../../voice/spec/agent-loop.md)).
  Cheap, deterministic.
- **Verifier judgment** — a verifier role reads the branch diff, the spec, and the executor's
  mechanical results, and produces a structured **verdict**
  ([`../../voice/spec/report.md`](../../voice/spec/report.md)): does the change actually satisfy
  the spec, including what the commands miss.

The verifier's behaviour is `harmony/skills/verify/SKILL.md`.

## Worktree carve-out

The verifier must see the executor's work, so verify-loop dispatches break the reset-to-base rule:

| Dispatch | Worktree base |
|----------|---------------|
| Initial executor | `score/<id>` fresh from default-branch tip (normal) |
| Verifier (in loop) | `score/<id>` **at its current tip** — reads the executor's commits |
| Rework executor (in loop) | `score/<id>` **at its current tip** — continues the work |
| Independent dispatch (new ticket, exit-`1` retry, re-dispatch from `awaiting_input`/`specced`) | reset to base (unchanged) |

This is a **bounded** exception to the worktree-idempotency invariant (`state-model.md`,
[`../../voice/spec/workspace.md`](../../voice/spec/workspace.md), `CONTRACT.md`): the verify loop
is a tight inner loop on one coherent piece of work, so it preserves the branch. Independent
dispatches still reset to base.

## Convergence & findings

- **Findings channel.** A `fail` verdict's findings are committed to `spec.rework_notes` — the
  same channel the human uses for rework, now with Harmony as a second author
  (`ticket-format.md`). The re-dispatched executor reads them as context.
- **Cycle bound.** `max_verify_cycles` (config; default TBD — `../BACKLOG.md`) bounds the loop. On
  exhaustion the ticket surfaces to `reviewing` carrying the outstanding findings, and the human
  decides (approve, manual rework, respec, or block). Same convergence-bound concept as Voice's
  chunked-progress handoff ([`../../voice/spec/failure-contract.md`](../../voice/spec/failure-contract.md)).

## Restart safety (graceful degradation)

The loop position (which sub-run, the cycle count) is ephemeral run-state and does not survive a
Harmony restart. It does not need to. Because findings are committed to `spec.rework_notes` as the
loop runs, a restart mid-loop falls back to the existing recovery:

1. `building → ready` reset (`state-model.md` restart recovery).
2. Re-dispatch from base, with `rework_notes` carrying the accumulated findings.

i.e. the loop degrades to the standard no-resume rework model — knowledge survives via notes; only
the in-progress branch work re-runs. No special restart handling, and no committed `verifying`
status needed. (If wasted-work-on-restart ever proves costly, a committed `verifying` phase marker
is the upgrade — `../BACKLOG.md`.)

## WIP interaction

A ticket holds **one** `building` slot for the whole loop — the executor and verifier run
sequentially, never concurrently. The loop lengthens a ticket's `building` occupancy but consumes
no extra slots. It *reduces* `human_inbox` pressure by surfacing only converged work to
`reviewing`.

Caveat: the verifier is itself a Voice run and may exit `needs-input` or `infeasible` — which *do*
hit the inbox (`awaiting_input` / `specced`), exactly as an executor run can.
