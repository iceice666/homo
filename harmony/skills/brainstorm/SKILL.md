---
name: yjsp-brainstorm
description: Sharpen a rough idea into one or more yjsp tickets. Use when you have a vague problem, instinct, or "we should fix X" thought and need to clarify it before writing a spec. Output is draft ticket(s) written directly to .yjsp/tickets/.
argument-hint: "<rough idea or problem description>"
---

# yjsp-brainstorm

Turn a rough idea into a ticket (or a set of tickets). This is a conversation, not a workshop.

## Usage

```
/yjsp-brainstorm <rough idea>
```

## What This Does

Takes what's in your head — vague, half-formed, or specific — and sharpens it into something
concrete enough to become a yjsp ticket. At the end it writes one or more `backlog` ticket
files directly to `.yjsp/tickets/` so you can immediately follow up with `/yjsp-spec`.

## Workflow

### 1. Frame in one exchange

Ask at most one clarifying question before starting. The goal is to understand:
- Is this a **problem** ("X is broken / slow / annoying") or a **solution** ("I want to add Y")?
- Which project does it belong to?

If it's stated as a solution, probe the problem first:
> "What's the symptom that made you think of this? What happens today without it?"

If it's already a clear problem, move straight to step 2.

### 2. Stress-test the idea (adversarial mode)

You are a sharp sparring partner, not a scribe. Challenge before building.

Ask the questions that would kill a bad idea cheaply:

**Is it real?**
- "Is this blocking something or just annoying? Would you notice in a week if it wasn't fixed?"
- "Have you hit this problem more than once, or is this a one-off?"

**Is it the right problem?**
- "What's the root cause? Is there a simpler underlying issue worth fixing instead?"
- "What are you actually trying to achieve? Is this change the best path to that?"

**Is now the right time?**
- "Which of your projects is this for? Is that project hot or warm right now?"
- "If you fix this, does it unblock anything? Or is it standalone?"

**What kind of work is it?**
- Is this a bug, a feature request, a refactor, or a chore? (sets the tag)
- Does it need to run on a specific machine — macOS only, Linux only, or any? (sets `target.platform`)

**Is the scope right?**
- "Can one executor handle this in a single branch, or does it naturally split into parts?"
- "What's out of scope — what would you explicitly NOT fix in the same ticket?"

Push back when the idea is vague or solution-first. One good challenge beats five generated ideas.

### 3. Scope check — one ticket or many?

A ticket should be reviewable in one sitting. If the idea is too large, split it now
rather than discovering the split mid-build.

Signs it should split:
- "And also..." appears more than once
- Different parts of the change would go to different reviewers
- Part A blocks Part B (natural `blocked_by` relationship)
- One part is visual/interaction, another is pure logic

If splitting, name each part and their dependency order. The first ticket is the one
to spec and run; the others go to `backlog`.

### 4. Gut check — do you actually need this?

You're a solo dev with limited hours and an inbox cap. Ask once:

> "If you had 3 hours this week, would you spend one of them on this? Or is something else
> more important right now?"

If the answer is uncertain, the ticket goes to `backlog`, not `draft`. Don't oversell ideas.

### 5. Write the ticket(s)

Once the idea is sharp enough, write the ticket file(s) to `.yjsp/tickets/<id>.yaml`.

Use the minimum viable content for the current state:
- If idea is still fuzzy → `state: backlog`, just `title` + `notes`
- If it's clear enough to spec → `state: draft`, `title` + `notes` ready for `/yjsp-spec`

```yaml
schema: yjsp.ticket/v1
id: <slugified-title>
state: backlog | draft
title: "<concrete title — verb + noun>"
project: <project-id>
created: "<today>"
notes: "<what you'd tell an agent in 2-3 sentences>"
tags: [<bug|fr|chore|refactor|docs|macos|linux|android|hot-fix|perf>]
spawned_from: ~
blocks: []
blocked_by: []
target:
  platform: any   # any | macos | linux | android | ios | web
  capabilities: []
```

Pick `tags` from the conversation — at minimum one type tag (`bug`, `fr`, `chore`, `refactor`,
`docs`). Add a platform tag (`macos`, `linux`, `android`) if the work is platform-specific.
Set `target.platform` to match: if it's a `macos` tag ticket, set `platform: macos`; if it
could run anywhere, leave `any`.

After writing, print:
```
✓ Created .yjsp/tickets/<id>.yaml (draft)
  Tags: [bug, macos] · Target: macos
  Next: /yjsp-spec <id>  — to write the execution spec
```

Or if multiple tickets:
```
✓ Created 2 tickets:
  .yjsp/tickets/add-theme-switch-system.yaml (draft) [chore] · any  ← do first
  .yjsp/tickets/add-dark-mode.yaml (backlog)         [fr]    · any  ← blocked by above
  Next: /yjsp-spec add-theme-switch-system
```

## Principles

**Problem before solution.** If the user comes in with "I want to add X", find the problem X
solves before writing the ticket. A ticket scoped to the problem is almost always better than
one scoped to the proposed solution.

**One question at a time.** Don't dump a list of questions. Ask the most important one, wait
for the answer, then ask the next if needed.

**Short sessions.** This should take 5 minutes, not 30. If the conversation is still going
after 5 exchanges, the idea probably needs to be broken into smaller questions.

**Take positions.** "I think this should be two tickets because..." is more useful than
presenting options neutrally. You have enough context to have an opinion.

**Don't oversell.** A solo dev with an inbox cap should be picky about what enters the
pipeline. If an idea doesn't survive basic scrutiny, say so directly.
