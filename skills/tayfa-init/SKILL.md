---
name: tayfa-init
description: Scaffold Tayfa's dev/coordination directory in a repository. Use when setting up Codex multi-agent coordination with workstreams, an AGENTS.md registry, onboarding guidance, scratchboards, tasks, memos, and change logs for the first time.
---

# Initialize Tayfa

1. Run `bash <this-skill-directory>/init.sh` from the project root. Resolve
   `<this-skill-directory>` to the directory containing this `SKILL.md`.
   Stop if `dev/coordination/` already exists; do not overwrite it.
2. Replace `{{PROJECT_NAME}}` in `README.md` and `AGENTS.md` with the
   human-readable project name.
3. Replace `{{PROJECT_DOC_PATH}}` in `ONBOARDING.md` and `AGENTS.md` with the
   repository's primary architecture or overview document. If none exists,
   keep the TODO and tell the user.
4. Add repository-wide commands, boundaries, and verification requirements to
   the Codex guidance section of `dev/coordination/AGENTS.md`.
5. Report the created files and suggest `$tayfa-add-agent` followed by
   `$tayfa-add-workstream`.

Do not stage or commit the scaffold unless the user asked for Git changes.
