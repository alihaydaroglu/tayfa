---
name: tayfa-add-workstream
description: Create a new workstream file in a tayfa-managed coordination directory. Use when opening a new line of work that needs its own task list, memos, and change log (e.g. "frontend", "bugs", "auth-rewrite"). Creates dev/coordination/<slug>.md from the template; the user must then add a row to README.md's workstream table.
---

# tayfa-add-workstream

Create a new workstream file at `dev/coordination/<slug>.md`.

## Inputs

- A short slug (the file name, without extension): `webapp`, `bugs`,
  `auth-rewrite`, etc. Lowercase, hyphens or underscores.
- A human-friendly title for the workstream header: "Webapp Stack",
  "Cross-cutting Bug Tracker", "Auth Rewrite". Multi-word OK.

If you don't have a clear slug + title from the user, ask before
running the script.

## Steps

1. **Run the helper.** Creates `<slug>.md` from the workstream
   template. Refuses if the file already exists.
   ```bash
   bash ${CLAUDE_SKILL_DIR}/add_workstream.sh <slug> "<title>"
   ```

2. **Add a row to `dev/coordination/README.md`** under the `## Workstreams`
   table. Format:
   ```
   | [<slug>.md](<slug>.md) | <one-line scope description> | Active — opened YYYY-MM-DD |
   ```
   If the table still has the placeholder row, replace it.

3. **Customise the new file:**
   - Replace the description placeholder (top of file) with a real
     one-paragraph description of what this workstream covers and why.
   - Fill in the "Agents active in this stream" line with the
     relevant `@tag`s.
   - Replace the "Current Sprint" goal placeholder.
   - Add the first task(s) under `### Tasks — @<tag>`.
   - Update the change log entry with today's date.

4. **Confirm to the user** what was created and what to do next
   (typically: tag the relevant agents in the new file's tasks).
