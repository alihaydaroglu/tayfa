---
name: tayfa-add-agent
description: Register a new agent in a tayfa-managed coordination directory. Use when adding a new agent (@tag) to an existing dev/coordination/ — creates their scratchboard at scratchboards/<tag>/main.md, and optionally gives them a project-defined ROLE (dev/coordination/roles/<role>.md) whose setup runs once and whose instructions the agent reads at onboard. The user must then add a row to AGENTS.md describing the agent's role, scratchboard path, and active workstreams.
---

# tayfa-add-agent

Register a new agent (`@<tag>`) in the project's coordination dir.

## Inputs

- The agent's tag (the bare word, no leading `@`). Examples: `backend`,
  `design`, `move_system`, `dynamicrafter`.
- A one-line role description (you'll need this for the AGENTS.md row).
- The list of workstreams the agent will be active in (file names from
  `dev/coordination/*.md` minus README/AGENTS/ONBOARDING).
- **Whether the agent fits a project ROLE.** If `dev/coordination/roles/`
  exists, read the head of each `roles/<role>.md`: it says **who gets the
  role** and **what setup args it takes**. If the agent the user is
  describing matches (for example, in nima, anyone making a piece of
  marketing content gets `director`), use it. Do not ask the user to
  confirm an obvious match; do ask if it is genuinely ambiguous.

If you don't have these yet, ask the user before running the script.

## Steps

1. **Run the helper.** Creates the scratchboard skeleton at
   `dev/coordination/scratchboards/<tag>/main.md`. Refuses if the
   directory already exists (unless `--role` is given, see below).
   ```bash
   bash ${CLAUDE_SKILL_DIR}/add_agent.sh <tag>
   # with a project role; setup args are whatever roles/<role>.md asks for
   bash ${CLAUDE_SKILL_DIR}/add_agent.sh <tag> --role <role> [setup args...]
   ```
   With `--role`, the helper records the role in
   `scratchboards/<tag>/ROLE` and runs `roles/<role>.sh <tag> [args]` if
   the project has one. The hook is idempotent, so **`--role` on an
   agent that already exists attaches the role** rather than refusing.
   If the hook fails, fix the args and re-run the same command.

2. **Add a row to `dev/coordination/AGENTS.md`** under the `## Agents`
   table. The format is:
   ```
   | @<tag> | <role description> | [<tag>/main.md](scratchboards/<tag>/main.md) | <workstream1>, <workstream2> |
   ```
   If the table still has the placeholder row (`_(none yet — ...)_`),
   replace it with the new agent's row instead of adding a second row.
   If the agent has a project role, say so in the description (the role
   hook may print a suggested line).

3. **Wire the agent into the workstream files** they're active in: add
   a `### Tasks — @<tag>` section under `## Current Sprint` if they
   have open work, or just mention them in the workstream's "Agents
   active in this stream" line so other agents know they exist. A role
   hook may already have done this; check before adding a second block.

4. **Confirm to the user** what was created and what they should do next
   (typically: spin up the new agent and have it run `/tayfa-onboard
   <tag>`; its role, if any, is picked up at step 5b of that ritual).
