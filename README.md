# tayfa

A standalone, project-agnostic coordination system for multi-agent
software work. Drop it into any repo and it gives you:

- A `dev/coordination/` directory with a small set of conventions for
  workstreams, agents, tasks, memos, and change logs.
- An `inbox` tool that scans every coordination file and shows an
  agent everything addressed to them — open tasks, open bugs,
  unresolved memos.
- A handful of Claude Code skills that automate the scaffolding and
  the day-to-day rituals.

It is the system that grew up inside the `nima` repo, lifted out so
other projects can use it without dragging nima along.

> **Name.** *Tayfa* is Turkish for *crew* / *gang* — the small group
> of people working a job together. The agents (human or LLM) on a
> project are its tayfa.

## Install

```bash
cd /home/ali/packages/tayfa
./install.sh
```

The installer symlinks each skill into `~/.claude/skills/` and
`bin/tayfa-inbox` into `~/.local/bin/` (if that directory exists and
is on your PATH). Symlinks mean edits to this repo take effect
immediately — no re-install needed.

## Skills

| Skill | What it does |
|-------|--------------|
| `tayfa-init` | Scaffold `dev/coordination/` in the current project. One-shot setup. |
| `tayfa-add-agent` | Register a new agent (`@tag`) and create their scratchboard. |
| `tayfa-add-workstream` | Create a new workstream file from the template. |
| `tayfa-onboard` | Fresh-context opening ritual for an agent: read the system, find the work. |

Invoke from Claude Code with `/tayfa-init`, `/tayfa-onboard backend`,
etc., or let Claude pick the right one based on intent.

## CLI

```
tayfa-inbox <tag>                       # tasks/bugs/memos addressed to @tag
tayfa-roster                            # awake agents (PID-validated)
tayfa-ping <tag> "<message>"            # ping an agent (tmux + log + notify)
```

All three walk up from the current working directory looking for
`dev/coordination/AGENTS.md` and use the directory they find. Pass
`--coord-dir <path>` to override.

### Presence + ping

Every agent that runs `/tayfa-onboard <tag>` registers itself in
`dev/coordination/.presence/<tag>.json` (PID, tty, tmux target, start
time). `tayfa-roster` reads that directory, validates each entry by
`kill -0 <pid>` (and `tmux has-session` if a tmux target was
recorded), and prunes stale ones inline. No background heartbeat
required — when the session dies, the PID stops being valid and the
entry is GC'd on the next roster read.

`tayfa-ping <tag> "<message>"` always appends to
`dev/coordination/.pings/<tag>.log` (the durable inbox — surfaced on
that agent's next `tayfa-onboard`), and additionally:
- if the recipient has a tmux target, injects the message into their
  pane via `tmux send-keys` (real-time wake-up).
- fires `notify-send` to your desktop if available (so you see it
  too).

Tag collisions are refused: if `@backend` is already registered with
a live PID, a second session can't claim the same tag — pick a
different one.

`.presence/` and `.pings/` are gitignored automatically by `tayfa-init`.

## Conventions in one breath

- One coordination file per **workstream** (e.g. `webapp.md`,
  `bugs.md`). Lives at `dev/coordination/<name>.md`.
- One **agent** per `@tag`. Registered in `AGENTS.md`.
- Tasks live under `### Tasks — @<tag>` in a workstream file. Open
  tasks are `- [ ]`, completed flip to `- [x]` and the tag flips
  `@tag` → `#tag`.
- **Memos** are `###`-headed sections in a workstream file with a
  `**To:** @<tag>` line. Acknowledge by flipping the addressed tag
  to `#`. Strike through the memo header with `~~` once everyone
  has acknowledged.
- Each agent has a private **scratchboard** at
  `scratchboards/<tag>/main.md`. Other agents don't read it.
- Every workstream file has a **Change Log** at the bottom — one
  reverse-chron line per material change.

The full conventions live in the scaffolded `README.md` and
`AGENTS.md` once you run `tayfa-init`.

## Layout

```
packages/tayfa/
├── README.md           ← you are here
├── install.sh
├── bin/
│   └── tayfa-inbox     ← project-agnostic inbox tool
├── skills/             ← Claude Code skills, one dir each
│   ├── tayfa-init/
│   ├── tayfa-add-agent/
│   ├── tayfa-add-workstream/
│   └── tayfa-onboard/
└── templates/          ← markdown templates copied into projects
    ├── README.md.tmpl
    ├── AGENTS.md.tmpl
    ├── ONBOARDING.md.tmpl
    ├── workstream.md.tmpl
    └── scratchboard_main.md.tmpl
```

## Origin

Lifted out of `nima/dev/coordination/` on 2026-04-23. The nima copy
remains untouched and self-contained — tayfa is a parallel, generalised
version that other projects can adopt without coupling.
