---
name: tayfa-add-workstream
description: Create and initialize a workstream in an existing Tayfa coordination directory. Use when opening a distinct line of work that needs its own goal, owned task list, memos, status, and change log.
---

# Add a Tayfa workstream

Obtain a lowercase slug and human-readable title. Ask only when they cannot be
inferred safely.

1. Run `bash <this-skill-directory>/add_workstream.sh <slug> "<title>"`,
   resolving the skill directory to the folder containing this `SKILL.md`.
2. Add the workstream to the table in `dev/coordination/README.md`, replacing
   its placeholder row if necessary:

   ```text
   | [<slug>.md](<slug>.md) | <scope> | Active — opened YYYY-MM-DD |
   ```

3. Replace the generated description and sprint-goal placeholders.
4. List active agent tags, add the initial owned tasks, and update the change
   log with today's date.
5. Report the new file and any unassigned work that still needs an owner.
