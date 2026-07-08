---
name: tayfa-onboard
description: Onboard as an agent in a tayfa-managed project. Use when spinning up with a fresh context as a specific agent (@tag) and you need to understand the system, find your work, and start being useful. Walks through the standard opening ritual: read system docs, run the inbox, read your scratchboard, then read the relevant workstream file and linked specs.
---

# tayfa-onboard

Opening ritual for a fresh agent context. The user invokes this with
their tag, e.g. `/tayfa-onboard backend`. If no tag was given, ask
the user which `@tag` they're onboarding as before proceeding.

## The ritual

Do these steps in order. Each one is short — the whole thing is ~15
minutes of reading. Don't skip steps even if you think you know the
project.

1. **Know the system.** Read `dev/coordination/README.md` and
   `dev/coordination/AGENTS.md`. You'll learn the workstream layout,
   the agent registry, and the `@tag` / `#tag` / `~~` conventions.

2. **Understand the project.** Read the project's main architecture
   doc — `dev/coordination/ONBOARDING.md` names it under step 2.
   Read **the whole file**, even if you're a bug-fix agent. You can't
   meaningfully change a system you don't understand.

3. **Register your presence.** Run:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/register_presence.sh <tag>
   ```
   This writes your session's PID to
   `dev/coordination/.presence/<tag>.json`, surfaces any pings queued
   while your tag was offline, and plugs you into the pulse system
   (heartbeats + `tayfa-roster`; see "Presence, beats, and the roster"
   below). If it refuses because the tag is already registered to a
   live session, tell the user — there may be a duplicate session —
   and continue the ritual without registering.

4. **Find your work.** Run:
   ```bash
   tayfa-inbox <tag>
   python dev/coordination/ali_ask.py check <tag>   # @ali's answers to you
   ```
   Lists open tasks, open bugs, and unresolved memos addressed to
   `@<tag>`, with file:line refs. If the inbox is empty, ask the user
   what they want you to work on — don't invent work.

5. **Read your scratchboard.** Open
   `dev/coordination/scratchboards/<tag>/main.md` (or the directory if
   the agent uses a richer memory layout). This is your private
   workspace from prior sessions — plans, half-formed thoughts, links.

6. **Read the workstream file(s) the inbox pointed at.** Focus on the
   `## Current Sprint` section for context, then skim the other
   agents' tasks so you know what's happening around you. Skip
   historical change-log entries unless something is unclear.

7. **Read the specs linked from your task.** Workstream task entries
   should link to design docs or specs — those are the design
   contract. Read the ones your work touches.

## After the ritual

Tell the user, in 2–3 sentences:
- The tag you're onboarding as.
- The shape of your inbox (e.g. "3 open tasks, 1 memo, no bugs").
- What you're going to do first (the highest-priority item from the
  inbox, or a question if you need clarification).

Then start work.

## Conventions reminder (when you finish a task)

1. Flip `@tag` → `#tag` on completed items in the workstream file.
2. Add a one-line entry to the workstream's Change Log.
3. Update your scratchboard with anything future-you should remember.
4. If you resolved a memo addressed to you, strike its header through
   with `~~` only after **all** addressed agents have flipped to `#`.

## Make features reviewable (@ali standing rule, 2026-07-08)

When you implement a NEW FEATURE (not a pure bug fix or refactor),
**build @ali a visual review** — he has a short attention span and will
not read long texts:

1. Host a small demo/preview page **locally** and register it on the
   :8532 portal (the only LAN door): bind your server to `127.0.0.1`,
   then `python dev/local/portal/register.py --slug <feature> --port
   <port> ...` (tear down with `--unregister` when reviewed). Do NOT
   use Claude artifacts for feature review — @ali reviews at
   `http://<box>:8532/`.
2. The page should SHOW the feature (screenshots, live UI, before/
   after, gallery — whatever fits) plus a few bullet lines of what's
   implemented. Bullets, not essays.
3. Post the portal link in your DONE memo, **and send it to @ali's inbox**:
   `python dev/coordination/ali_ask.py fyi --from <tag> --title "..."
   --link /s/<slug>/`. Questions for @ali also go through `ali_ask.py ask`
   (with `--context`); poll his answers with `ali_ask.py check <tag>`.

Good exemplars: the ltx spike gallery, the KFE UI preview.

## Presence, beats, and the roster ("tayfa pulse")

Registration (ritual step 3) plugs your session into three things:

- **Pings** — other agents can `tayfa-ping <tag> "<msg>"` you in real
  time; offline pings queue in `.pings/<tag>.log` and are surfaced at
  your next registration.
- **Heartbeats** — if the machine has the `tayfa-beat` Stop hook
  installed (user-level `~/.claude/settings.json`), every registered
  session automatically writes `.presence/beats/<tag>.json` at the end
  of every turn, cron ticks included. No action needed from you. You
  can also beat manually to publish a status line on the roster:
  ```bash
  tayfa-beat --note "tick 14 — holding on review gate"
  ```
  The note persists across automatic beats until you replace it —
  keep it current at milestones; it's what the human sees at a glance.
- **The roster** — `tayfa-roster` (CLI) or `tayfa-roster --serve
  --port 8533` (loopback web page + `/roster.json`) shows who's AWAKE
  (fresh beat), QUIET (session alive but no recent beat — idle, or its
  cron/loop died and needs re-arming), or GONE (session ended).

If registration was refused (tag taken by a live session), pings and
beats for that tag belong to the other session — don't fight over it.
