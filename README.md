# tayfa-codex

A small, project-agnostic coordination system for running multiple Codex
agents against one software project. Tayfa keeps durable coordination in
plain Markdown instead of tying it to a particular task or context window.

It provides:

- `dev/coordination/` conventions for workstreams, agents, tasks, memos,
  scratchboards, and change logs.
- `tayfa-inbox`, which finds open work addressed to an agent tag.
- `tayfa-ask`, a file-backed question and acknowledgement channel between
  agents and the human project owner.
- Five Codex skills for setup, onboarding, and project management.

This Codex edition deliberately has no presence registry, heartbeat, hook,
tmux, roster, ping, or Slack machinery. Agent state is the coordination
directory plus the state of the Codex tasks themselves.

## Install

Run on Linux, macOS, or WSL:

```bash
cd /path/to/tayfa
./install.sh
```

The installer symlinks skills into `${CODEX_HOME:-~/.codex}/skills` and
`tayfa-inbox` plus `tayfa-ask` into `${TAYFA_BIN_DIR:-~/.local/bin}`.
Symlinks make changes to this checkout take effect without reinstalling.

Start a new Codex task after installation so the skills are rediscovered.

## Skills

| Skill | Purpose |
|---|---|
| `tayfa-init` | Scaffold `dev/coordination/` in a project. |
| `tayfa-add-agent` | Register an agent tag and create its scratchboard. |
| `tayfa-add-workstream` | Create a workstream from the bundled template. |
| `tayfa-onboard` | Rebuild context and find work for a tagged agent. |
| `tayfa-kalfa` | Act as the coordinating foreman for a multi-agent push. |

Ask Codex naturally, such as “use tayfa-onboard as backend,” or explicitly
name the skill as `$tayfa-onboard` when the client supports skill mentions.

## Core commands

```text
tayfa-inbox <tag>       show open tasks, bugs, and memos for an agent
tayfa-ask ask ...       send a question to the human owner
tayfa-ask fyi ...       send an informational item
tayfa-ask check <tag>   read answers addressed to an agent
tayfa-ask list          list human-inbox items
tayfa-ask answer ...    answer an agent question as the human owner
tayfa-ask seen <id>     mark an FYI seen as the human owner
tayfa-ask ack <id>      acknowledge an answered or seen item
```

Both commands walk upward from the current directory to find
`dev/coordination/AGENTS.md`. Use `--coord-dir <path>` when working from
outside the project tree.

## Coordination conventions

- One Markdown file per workstream: `dev/coordination/<stream>.md`.
- One agent identity per `@tag`, registered in `AGENTS.md`.
- Open tasks are unchecked items under `### Tasks — @<tag>`.
- Completing an assignment changes `@tag` to `#tag`.
- Memos are headed sections with a `**To:** @<tag>` line.
- A memo is struck through only after every recipient acknowledges it.
- Each agent owns `scratchboards/<tag>/main.md`; other agents do not read it.
- Material coordination changes receive a reverse-chronological change-log
  entry in the owning workstream.

The generated `README.md`, `AGENTS.md`, and `ONBOARDING.md` contain the full
working protocol.

## Layout

```text
tayfa/
├── README.md
├── install.sh
├── bin/
│   ├── tayfa-inbox
│   └── tayfa-ask
├── skills/
│   ├── tayfa-init/
│   ├── tayfa-add-agent/
│   ├── tayfa-add-workstream/
│   ├── tayfa-onboard/
│   └── tayfa-kalfa/
└── templates/
    ├── README.md.tmpl
    ├── AGENTS.md.tmpl
    ├── ONBOARDING.md.tmpl
    ├── workstream.md.tmpl
    └── scratchboard_main.md.tmpl
```

## Codex operating model

Tayfa does not create or monitor Codex tasks. The human or coordinating
agent starts the required tasks, assigns each one a unique Tayfa tag, and
passes the appropriate workstream context. Coordination remains durable in
the repository even when tasks end or context is compacted.

`AGENTS.md` is both the Tayfa registry and durable Codex repository guidance.
Keep it concise and include project commands, boundaries, and verification
requirements that every agent must follow.
