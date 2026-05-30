# Voice — System Prompt

Voice keeps the model's system prompt **minimal** and assembles it at runtime. The base prompt
(who you are, your goal) comes from the role manifest; Voice appends a small fixed **harness
addendum** describing the built-in tools it injected and the commit/stop/budget protocol. This
is consistent with `roles.md`: *Harmony resolves config; Voice does runtime assembly.*

## Philosophy: minimal, except the off-ramps

- **Who / goal / tools.** A good prompt says who the agent is, what it is trying to do, and what
  tools it has. The first two come from the role's base `system_prompt`; the ticket request (the
  first user message) carries the concrete goal.
- **Tools are schemas, not prose.** Tool availability is conveyed by the `echo` `Tool` schemas
  (`mcp-bridge.md`), not by listing tools in the prompt. The prompt only needs the *usage policy*
  for the built-ins, which the model cannot infer from a schema.
- **One part is deliberately not minimal: the off-ramp policy.** Voice runs **unattended**, and
  models lean toward being helpful — they will grind out a broken partial instead of calling
  `infeasible`, or guess instead of `needs_input`. So the highest-leverage prose in the prompt is
  the part that actively pushes the agent toward the off-ramps. Minimal everywhere else; emphatic
  there.

## Assembly order

System content, in order — the harness addendum is **last**, for salience:

```
1. base system_prompt        ← role manifest (Harmony): who you are + goal
2. repo AGENTS.md / CLAUDE.md ← project conventions, read from the worktree
3. skill.body                ← the role's how-to
4. harness addendum          ← Voice-injected, fixed: built-ins + commit/stop/budget protocol
─────────────────────────────
ticket request               ← first USER message (spec.*, pitch, notes)
```

See `roles.md` for the manifest inputs and `agent-loop.md` for per-turn context assembly.

## The harness addendum

Fixed text Voice appends for every role (it describes the harness, not the role):

```
You are running unattended in an isolated git worktree. Your committed changes are the
deliverable — commit as you work. When nothing is left to do, stop: that signals completion and
your committed work goes to review.

Three control tools. Use them — do not work around them:
  • infeasible(...) — call the moment the task cannot be built as written (missing prerequisite,
    contradictory spec). Do NOT grind out a broken partial. Say what is missing and what a
    buildable spec would look like.
  • needs_input(...) — call when you need a human decision, a secret, or an out-of-band action.
    Do NOT guess past a wall or fabricate a credential.
  • compact() — call at a clean stopping point if context is getting large, to summarize and
    continue.

Your budget (turns / tokens / time) is bounded. If the work is too large to finish, call
infeasible with a suggested split rather than running until you are cut off.
```

The built-ins named here are defined in `agent-loop.md` (exit signals) and `failure-contract.md`
(`compact`). Keep this text in sync with that built-in set.

## Ownership

| Layer | Owner | Why |
|-------|-------|-----|
| base prompt (who + goal) | Harmony role catalog | role identity is config Harmony resolves |
| `skill.body` | Harmony (`harmony/skills/`) | role how-to is config |
| repo `AGENTS.md` / `CLAUDE.md` | the repo, read by Voice | lives in the worktree |
| harness addendum | Voice (fixed) | describes the built-ins Voice itself injects |

Keeping the addendum in Voice keeps the role catalog free of harness-protocol boilerplate.
