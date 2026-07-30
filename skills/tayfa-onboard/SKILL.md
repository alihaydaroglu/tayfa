---
name: tayfa-onboard
description: Onboard or re-onboard a Codex agent into a Tayfa-managed repository under a specific agent tag. Use after starting a fresh task, losing context, changing agents, or asking an agent to find and begin its assigned Tayfa work.
---

# Onboard into Tayfa

Require a unique registered agent tag. If none was supplied, ask for it before
continuing.

1. Read `dev/coordination/README.md` and `dev/coordination/AGENTS.md`.
2. Read the entire project architecture document named in
   `dev/coordination/ONBOARDING.md`.
3. Run `tayfa-inbox <tag>` and `tayfa-ask check <tag>`.
4. Read only this agent's `scratchboards/<tag>/main.md`.
5. Read the current-sprint sections of workstreams reported by the inbox.
6. Read specifications linked by this agent's tasks.
7. Summarize the inbox, select the highest-priority unblocked task, and begin
   work unless it requires a material user decision.

Do not read another agent's scratchboard. Do not invent work when the inbox is
empty.

## While working

- Keep detailed private notes in the agent scratchboard.
- Communicate cross-agent information in the owning workstream as a memo.
- Ask the human owner through `tayfa-ask` when a decision is genuinely needed.
- Follow repository commands and boundaries in `AGENTS.md`.

## Finish an assignment

1. Verify the implementation using the repository's required checks.
2. Change the completed assignment's `@tag` to `#tag`.
3. Move completed tasks to `## Done` when that section exists.
4. Strike a memo only after every recipient has acknowledged it.
5. Add one reverse-chronological change-log line.
6. Update the scratchboard with durable context for the next task.

Report the result, verification evidence, remaining blockers, and files changed.
