# Harmony

A local Elixir/OTP daemon that maintains a real-time cache of ticket state derived from the
git repo, enforces WIP limits, dispatches Voice subprocesses, and exposes a Phoenix Channels
API to Aria.

> You define the work; Harmony keeps track, dispatches agents, and hands back only the
> decisions you need to make.

Harmony watches each registered project repo via git hooks (`post-commit`, `post-merge`).
When a ticket reaches `ready`, Harmony resolves the agent's **role** into a manifest and
dispatches a Voice subprocess (one per agent — Voice runs a native agent loop, reaching models
through `echo`) against an isolated git worktree, then commits the status transition to git.
When Voice finishes, Harmony commits the updated ticket state and notifies Aria.

All durable state lives in git — Harmony's in-memory cache is a derived projection. On restart
it reads `git HEAD` and rebuilds; tickets that were `building` are reset to `ready` via a
recovery commit. Harmony holds no authoritative state of its own.

## Docs

All design is in [`spec/`](spec/). No implementation code exists yet.

## Part of Partitura

One of four packages in the **Partitura** system. Harmony is the state manager at the centre —
[`aria`](../aria/) (the desktop UI) connects to it, and it dispatches [`voice`](../voice/)
(the agent harness) per agent. [`echo`](../echo/) is the unified LLM client that Voice links
for model calls.

## Status: spec-only
