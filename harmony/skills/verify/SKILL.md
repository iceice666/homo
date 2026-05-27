---
name: yjsp-verify
description: Run the verifier pass for a yjsp ticket in need-review state. Executes automated acceptance checks, diffs evidence, reviews the code, and writes review.md in the exact format the daemon expects. Use when a ticket has a handoff and needs a logic/correctness gate before human review.
argument-hint: "<ticket-id>"
---

# yjsp-verify

Run the full verifier pass on a yjsp ticket and write `review.md`.

## Usage

```
/yjsp-verify <ticket-id>
```

## What This Does

Reads the ticket spec, runs automated checks, diffs evidence, reviews the branch diff, and
writes `.yjsp/tickets/<id>/review.md`. The daemon watches for this file and auto-transitions
the ticket to `need-human` when it appears.

## Workflow

### 1. Load the ticket

Read `.yjsp/tickets/<id>.yaml`. Confirm state is `need-review` or `verifying`.
Read `.yjsp/tickets/<id>/handoff.md`.

If either file is missing, stop and report the gap.

### 2. Run automated acceptance checks

Execute each command in `spec.acceptance.automated` from the project root.
Capture: command, exit code, stdout (last 20 lines), stderr (last 10 lines).

Record each as `pass` (exit 0) or `fail` (non-zero).

### 3. Diff the evidence

List files under `.yjsp/tickets/<id>/evidence/`.
Compare against `spec.evidence_required`.

For each required item: present (✓) or missing (✗).

### 4. Review the diff

Read the diff on branch `yjsp/<id>` against the default branch.

**First, check spec compliance:**
- Does the implementation match `spec.what`?
- Does anything violate `spec.constraints`?
- If `spec.rework_notes` is non-empty, were all previous issues addressed?
- Read `handoff.md` deviations — if the agent went off-script, assess the risk.

**Then review for blocking issues only** across these dimensions.
Do not nitpick style or naming. Flag only what is `blocking` (must fix), `warning` (should fix),
or `note` (observation, no action required).

**Security**
- Injections (SQL, command, path traversal)
- Auth/authz gaps — missing checks, privilege escalation
- Secrets or credentials hardcoded in source
- Unsafe deserialization or eval

**Correctness**
- Edge cases not handled: empty input, null/nil, integer overflow, empty collections
- Race conditions or shared mutable state without synchronisation
- Error paths that silently swallow failures
- Off-by-one, wrong comparison operators

**Performance** (flag only if in a hot path or clearly O(n²)+)
- N+1 queries or unbounded loops over large collections
- Missing indexes on queried fields
- Memory leaks — resources opened but not closed

**Contracts**
- Public API or interface changes not covered by `spec.what`
- Breaking changes to data formats or serialisation

### 5. Write review.md

Write to `.yjsp/tickets/<id>/review.md` using exactly this structure:

```markdown
## Automated checks

| Command | Result | Notes |
|---------|--------|-------|
| `pnpm test` | ✓ pass | |
| `pnpm e2e mode-switching` | ✗ fail | exit 1 — "cannot find element .mode-indicator" |

## Evidence

| Required | Present |
|----------|---------|
| screenshot_matrix | ✓ |
| key_sequence_replay | ✗ missing |

## Code review

[blocking] <file>:<line> — <issue description>
[warning]  <file>:<line> — <issue description>
[note]     <file>:<line> — <observation>

(none) if clean.

## Verdict

pass | fail

### If fail — must fix before approval:
- <specific actionable item>
- <specific actionable item>
```

Do not add commentary outside this structure. The format is parsed by the human reviewing it.

### 6. Update ticket state

After writing `review.md`:
- Update `state:` in the ticket YAML to `need-human`.
- The daemon will pick this up. If running without the daemon, print:
  `✓ review.md written — run \`yjsp approve <id>\` or \`yjsp rework <id> "<note>"\``

## Verdict rules

**pass** — all automated checks pass AND no blocking code review issues AND all required
evidence is present. Warnings and notes do not block.

**fail** — any automated check fails OR any blocking code review issue OR any required
evidence is missing.

When in doubt, fail. A false negative wastes one iteration. A false positive wastes your
taste-review slot.
