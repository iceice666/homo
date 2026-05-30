# Harmony — Skills

Skill prompts are one component of a **role** (see `../../CONTRACT.md` → "Role manifest"). An
agent is a role — planner, builder, reviewer, … — and a skill supplies that role's specialised
system-prompt body.

Each skill is a directory containing a `SKILL.md` file. At dispatch, Harmony resolves the role
into a `score.role-manifest/v1`: it strips the skill's YAML frontmatter and embeds the body as
`skill.body`, alongside the base system prompt, model, tools, and budgets. Voice assembles the
final context from the manifest plus the repo's `AGENTS.md`/`CLAUDE.md`.

## Available skills

| Directory | Purpose |
|-----------|---------|
| `architecture/` | Architecture review before or during execution |
| `brainstorm/` | Brainstorm approaches to a problem before speccing a ticket |
| `debug/` | Diagnose a failing or blocked ticket |
| `deploy-checklist/` | Deploy readiness review |
| `documentation/` | Generate or improve documentation after a ticket lands |
| `incident-response/` | Incident diagnosis and remediation |
| `mode/` | Adjust project mode recommendations |
| `spec/` | Write or improve a ticket's execution spec |
| `tech-debt/` | Tech-debt survey and prioritisation |
| `triage/` | Pick what to work on next given a time budget |
| `verify/` | Verify a completed ticket (run checks, review evidence) |

## Skill file format

```markdown
---
name: spec
description: Write or improve a ticket's execution spec
---

<system prompt content here>
```

Frontmatter is stripped before the content is used. Only the body reaches the agent (as
`skill.body` in the role manifest).

## Resolution: global + repo

These package-level skills are the **global** catalog. A project's `.score/` may add or
override skills (repo wins on name collision), and likewise for the per-role model and MCP
servers — Harmony merges them when resolving the role manifest. See `../../CONTRACT.md` →
"Role manifest".

## Deferred decisions

- Whether skills remain a flat list or gain a category structure.
- The `verify` skill is the closest analogue to the old `yjsp-verify` role; the executor /
  verifier pipeline split has been dropped — a single dispatched agent handles the work and
  the human reviews.
