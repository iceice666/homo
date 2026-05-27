---
name: yjsp-mode
description: Change project modes (hot/warm/cold/frozen/maintenance) and priorities. Checks WIP limits before applying, warns on violations, and writes project.yaml directly. Use when shifting focus between projects.
argument-hint: "<instruction, e.g. 'cool down kaguya, heat up android-ime'>"
---

# yjsp-mode

Adjust project modes and priorities, with WIP limit enforcement.

## Usage

```
/yjsp-mode <instruction>
```

Examples:
```
/yjsp-mode cool down kaguya-browser, heat up android-ime
/yjsp-mode freeze drive-system until further notice
/yjsp-mode set statusbar to maintenance
/yjsp-mode what are the current modes
```

## Modes

| Mode | Meaning | Agents may run? |
|---|---|---|
| `hot` | Active focus — needs your taste/architecture judgment | yes |
| `warm` | Agents can proceed from specs, you check periodically | yes |
| `cold` | Parked — resumable but not actively worked | no |
| `frozen` | Intentionally ignored until you explicitly thaw it | no |
| `maintenance` | Low-risk upkeep only (fast-lane tickets, no new specs) | fast-lane only |

## Workflow

### 1. Read current state

Load `~/.yjsp/config.yaml` and each project's `.yjsp/project.yaml`.
Show the current mode/priority for every project before making changes.

### 2. Parse the instruction

Identify which projects are being changed and to what mode/priority.
If the instruction is ambiguous, confirm before writing anything.

### 3. Check WIP limits

Before applying changes, validate against `wip_limits` in `~/.yjsp/config.yaml`:

- `hot_projects` cap: count of projects transitioning to `hot` must not exceed limit
- A project going `cold`/`frozen` with active `building` tickets: warn that agents will be
  blocked mid-run. Ask to confirm.
- A project going `hot` when the `hot_projects` cap is already at limit: hard block.

```
✗ Cannot set android-ime to hot: hot_projects limit reached (2/2).
  Currently hot: kaguya-browser, drive-system.
  Cool one down first, or increase the limit in ~/.yjsp/config.yaml.
```

### 4. Write the changes

For each affected project, update `mode:` (and `priority:` if specified) in
`.yjsp/project.yaml`. Write directly — do not ask for confirmation unless there is a warning.

### 5. Confirm

```
✓ Mode changes applied:

  kaguya-browser  hot → warm
  android-ime     cold → hot  (now 2/2 hot projects — at limit)

WIP: hot 2/2 · building 1/4 · inbox 0/3
```

If a project has stale tickets (no progress in > mode threshold days), surface them:

```
⚠ android-ime has 1 stale ticket: stabilize-candidate-bar (14d, warm threshold)
  Consider reviewing or archiving before heating up.
```
