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

3. **Find your work.** Run:
   ```bash
   tayfa-inbox <tag>
   ```
   Lists open tasks, open bugs, and unresolved memos addressed to
   `@<tag>`, with file:line refs. If the inbox is empty, ask the user
   what they want you to work on — don't invent work.

4. **Read your scratchboard.** Open
   `dev/coordination/scratchboards/<tag>/main.md` (or the directory if
   the agent uses a richer memory layout). This is your private
   workspace from prior sessions — plans, half-formed thoughts, links.

5. **Read the workstream file(s) the inbox pointed at.** Focus on the
   `## Current Sprint` section for context, then skim the other
   agents' tasks so you know what's happening around you. Skip
   historical change-log entries unless something is unclear.

6. **Read the specs linked from your task.** Workstream task entries
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

## Optional: enable real-time pinging

Tayfa ships an opt-in presence registry so other agents can `tayfa-ping
<tag>` you in real time (and `tayfa-roster` to see who's awake). It is
**not required** — tasks, memos, and the inbox work fine without it.
Skip this section unless the user has asked for ping/roster.

If the user wants pinging enabled for this session, run:

```bash
bash ${CLAUDE_SKILL_DIR}/register_presence.sh <tag>
```

This writes the session's PID to `dev/coordination/.presence/<tag>.json`
and surfaces any pings queued in `.pings/<tag>.log` from while the tag
was offline. Refuses if the tag is already taken by a live session.
