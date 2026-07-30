---
name: tayfa-add-agent
description: Register a new agent tag in an existing Tayfa coordination directory and create its private scratchboard. Use when assigning a new Codex task or agent a stable Tayfa identity and workstream ownership.
---

# Add a Tayfa agent

Obtain the bare tag, one-line role, and active workstreams. Ask the user only
when these cannot be inferred safely.

1. Run `bash <this-skill-directory>/add_agent.sh <tag>`, resolving the skill
   directory to the folder containing this `SKILL.md`.
2. Add this row under `## Agents` in `dev/coordination/AGENTS.md`:

   ```text
   | @<tag> | <role> | [<tag>/main.md](scratchboards/<tag>/main.md) | <streams> |
   ```

   Replace the placeholder row when adding the first agent.
3. Add the agent to each active workstream. Create a
   `### Tasks — @<tag>` section only when it has assigned work.
4. Report the new identity and tell the user to start or steer a Codex task
   with `$tayfa-onboard` and that tag.

Never reuse a tag concurrently for two active tasks.
