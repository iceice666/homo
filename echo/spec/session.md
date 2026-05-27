# echo — Session model

## What a session is

A **session** is a named conversation thread. Sessions are scoped to a **profile** (default:
`default`). Multiple sessions per profile are supported; only one is active in a REPL instance.

```
~/.config/echo/
  config.toml              # global + profile-level settings (see config.md)
  profiles/
    default/
      history.jsonl        # append-only log of all messages across sessions
      sessions/
        <session-id>.json  # metadata: title, timestamps, message range in history
    work/
      …
```

## Message format

Each line in `history.jsonl` is a JSON object:

```json
{
  "session_id": "2026-0528-a3f9",
  "seq":        42,
  "role":       "user",
  "content":    "What's a monad?",
  "ts":         "2026-05-28T14:30:12Z",
  "backend":    "claude-api",
  "model":      "claude-sonnet-4-6"
}
```

Assistant messages include an additional `"tokens": { "input": N, "output": N }` field when
the backend reports usage.

`history.jsonl` is append-only. Old messages are never deleted or rewritten in-place.
Compaction (archiving old sessions) is a separate offline tool — not part of the REPL.

## In-memory state

`lib/session.ml` keeps an in-memory `state` value:

```ocaml
type state = {
  session_id : string;
  profile    : string;
  messages   : Message.t list;   (* oldest first *)
  backend    : string;
  model      : string option;
}
```

## Write-before-send invariant

**Before every backend call**, the user's message is appended to `history.jsonl` with a `fsync`.
If the process crashes during the backend call, the user message is preserved; the partial
assistant response is discarded (no assistant record was written). On next startup, echo detects
a trailing `user` record with no matching `assistant` record and offers to resend or discard.

## Context window management

Each backend has a configurable `max_context_tokens` limit (see `config.md`). Before a backend
call, `lib/session` trims the history to fit:

1. The system prompt is always included (counted against the budget).
2. The most recent N messages are kept, working backwards from the newest.
3. If the oldest kept message is an `assistant` turn (would create a malformed alternating
   sequence), it is dropped and the next `user` turn becomes the oldest.
4. A `[… N messages omitted …]` synthetic user turn is prepended when trimming occurs, so the
   model is aware context was cut.

Token counting: the `claude-api` and `openai` backends report actual token counts in their
responses, which are stored. For the `claude-cli` backend, character count / 4 is used as a
rough estimate.

## Session lifecycle

```
echo chat                   # resume last active session (or create one)
echo chat --new             # start a fresh session in the current profile
echo chat --session <id>    # resume a specific session
echo sessions list          # list all sessions for the active profile
echo sessions show <id>     # dump a session's messages
```

Session IDs are `<date>-<4-char-random>` (e.g. `20260528-a3f9`), consistent with the
run-ID scheme in `CONTRACT.md`.

## Profiles

A profile bundles a default backend, system prompt, and conversation history. Use profiles
to keep work and personal conversations separate, or to switch between API keys without
re-exporting env vars.

```sh
echo chat --profile work
echo chat --profile personal
```

Profile names match `[a-z0-9][a-z0-9-]*`. The `default` profile is created automatically
on first run.
