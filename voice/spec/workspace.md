# Voice — Workspace

Per-ticket workspace isolation via git worktrees.

---

## Setup

When Voice starts, it creates a git worktree for the ticket:

```sh
git worktree add <VOICE_WORKSPACE> -b score/<ticket-id>
```

`VOICE_WORKSPACE` is set by Harmony to `.score/workspaces/<ticket-id>/` relative to the
project root (absolute path passed via env var).

**Every dispatch gets a fresh worktree reset to the base/default-branch tip.** This holds for
the initial run, an exit-`1` retry, and a re-dispatch out of `awaiting_input` or `specced` alike.
Voice does not resume from on-disk state left by a prior run; progress is carried forward only
through ticket context (`spec.rework_notes`, `spec.respec_notes`, `spec.clarifications` — see
`protocol.md`). This guarantees every run starts from a defined state.

If a worktree already exists at that path (e.g. from a previous run that didn't clean up),
Voice removes it and recreates:

```sh
git worktree remove --force <VOICE_WORKSPACE>
git worktree add <VOICE_WORKSPACE> -b score/<ticket-id>
```

If the branch already exists (from a prior run), reset it to the tip of the default branch so the
new run starts clean:

```sh
git worktree add <VOICE_WORKSPACE> score/<ticket-id>
git -C <VOICE_WORKSPACE> reset --hard origin/<default_branch>
```

---

## CWD pin invariant

Voice (and its CLI subprocess) must always run with the working directory set to
`VOICE_WORKSPACE`. The CLI agent must not `cd` outside this directory. This invariant ensures
the agent's file operations stay within the isolated worktree.

Voice should pass the workspace path explicitly to the CLI adapter rather than relying on
inherited `$CWD`.

---

## What the CLI sees

Inside the worktree:
- Full project source at the tip of the default branch (or last known-good state).
- A `.score/` directory (carried from the branch) — ticket files are readable here.
- A fresh branch `score/<ticket-id>` ready for commits.

The CLI agent should commit its changes to this branch. Harmony or the human can then open a
PR or merge at review time.

---

## Cleanup policy

A worktree is retained only for *human inspection* while a ticket sits in a human-pending state.
It is never reused as a resume point — the next dispatch resets it to base regardless (see above).

| Trigger | Action |
|---------|--------|
| Voice exits `0` (completed → `reviewing`) | Worktree **kept** for inspection until ticket reaches `done`. |
| Voice exits `1` (failed → retry) | Worktree **removed**; the retry recreates a fresh one. |
| Voice exits `2` (hard abort → `blocked`) | Worktree **removed** (`git worktree remove --force`). |
| Voice exits `3` (infeasible → `specced`) | Worktree **kept** for inspection while the human re-shapes the spec. |
| Voice exits `4` (needs-input → `awaiting_input`) | Worktree **kept** for inspection while the human answers. |
| Voice exits `5` (cancelled → `ready`) | Worktree **removed**. |
| Ticket reaches `done` or `blocked` | Worktree **removed** (Harmony triggers cleanup). |
| Harmony restart | Orphaned worktrees (no matching `building` ticket) are **removed** on startup. |

---

## Workspace root

The workspace root is `.score/workspaces/` relative to the project repo. This directory
should be added to the project's `.gitignore`:

```
.score/workspaces/
```

The tickets and runs subdirectories under `.score/` are **not** gitignored — they commit
with the repo.
