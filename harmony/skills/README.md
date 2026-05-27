# Harmony — Skills

Agent skill prompts used when Harmony dispatches Voice with a specific skill role.

Each skill is a directory containing a `SKILL.md` file. When a ticket specifies a skill,
Harmony passes the skill file path to Voice, which prepends its content to the CLI agent's
system prompt after stripping YAML frontmatter.

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

Frontmatter is stripped before the content is used. Only the body reaches the CLI agent.

## Deferred decisions

- Whether skills remain a flat list or gain a category structure.
- Whether skills can be repo-local (`.score/skills/`) overriding these package-level defaults.
- The `verify` skill is the closest analogue to the old `yjsp-verify` role; the executor /
  verifier pipeline split has been dropped — a single dispatched agent handles the work and
  the human reviews.
