---
name: tayfa-add-agent
description: Register a new agent in a tayfa-managed coordination directory. Use when adding a new agent (@tag) to an existing dev/coordination/ — creates their scratchboard at scratchboards/<tag>/main.md. The user must then add a row to AGENTS.md describing the agent's role, scratchboard path, and active workstreams.
---

# tayfa-add-agent

Register a new agent (`@<tag>`) in the project's coordination dir.

## Inputs

- The agent's tag (the bare word, no leading `@`). Examples: `backend`,
  `design`, `move_system`, `dynamicrafter`.
- A one-line role description (you'll need this for the AGENTS.md row).
- The list of workstreams the agent will be active in (file names from
  `dev/coordination/*.md` minus README/AGENTS/ONBOARDING).

If you don't have these yet, ask the user before running the script.

## Steps

1. **Run the helper.** Creates the scratchboard skeleton at
   `dev/coordination/scratchboards/<tag>/main.md`. Refuses if the
   directory already exists.
   ```bash
   bash ${CLAUDE_SKILL_DIR}/add_agent.sh <tag>
   ```

2. **Add a row to `dev/coordination/AGENTS.md`** under the `## Agents`
   table. The format is:
   ```
   | @<tag> | <role description> | [<tag>/main.md](scratchboards/<tag>/main.md) | <workstream1>, <workstream2> |
   ```
   If the table still has the placeholder row (`_(none yet — ...)_`),
   replace it with the new agent's row instead of adding a second row.

3. **Wire the agent into the workstream files** they're active in: add
   a `### Tasks — @<tag>` section under `## Current Sprint` if they
   have open work, or just mention them in the workstream's "Agents
   active in this stream" line so other agents know they exist.

4. **Confirm to the user** what was created and what they should do next
   (typically: spin up the new agent and have it read ONBOARDING.md).
