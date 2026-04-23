---
name: tayfa-init
description: Scaffold a tayfa coordination directory in the current project. Use when setting up multi-agent coordination (tasks, agents, memos, change logs) for the first time in a repo. Creates dev/coordination/ with README, AGENTS registry, ONBOARDING ritual, and an empty scratchboards/ dir. One-shot setup.
---

# tayfa-init

Initialize a tayfa coordination directory at `dev/coordination/` in
the current project.

## Steps

1. **Run the init script.** Copies templates into the project and
   creates the directory structure. Aborts cleanly if
   `dev/coordination/` already exists.
   ```bash
   bash ${CLAUDE_SKILL_DIR}/init.sh
   ```

2. **Fill in placeholders.** The scaffolded files contain two
   placeholders that need project-specific values:
   - `{{PROJECT_NAME}}` in `dev/coordination/README.md` and
     `dev/coordination/AGENTS.md` — the human-friendly project name.
   - `{{PROJECT_DOC_PATH}}` in `dev/coordination/ONBOARDING.md` — the
     path (relative to repo root) of this project's main architecture
     or overview doc that every onboarding agent must read.

   Use `Edit` with `replace_all: true` for each substitution. If the
   project has no main architecture doc yet, leave the TODO note in
   place rather than inventing a path — onboarding agents will see
   the TODO and ask.

3. **Suggest next moves to the user.** Report what was scaffolded and
   point at the obvious next steps:
   - `tayfa-add-agent <tag>` to register the first agent.
   - `tayfa-add-workstream <name>` to open the first workstream.
   - Add `dev/coordination/` to git: `git add dev/coordination/`.

## What gets created

```
dev/coordination/
├── README.md
├── AGENTS.md
├── ONBOARDING.md
└── scratchboards/.gitkeep
```

No workstream files and no agents yet — those are added later via
the other tayfa skills.
