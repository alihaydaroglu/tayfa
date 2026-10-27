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

This package has been designed and developed in collaboration with Claude.

>  **Tayfa** (_Turkish_): crew / gang — a group of people working a job together. 

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
| `tayfa-kalfa` | Become the **kalfa** (foreman / PM agent): run the crew toward a goal — stage the work, drive the loop, route + adjudicate, tee the human (**usta**) up for sign-off. Directs + verifies; never writes feature code or deploys. |

Invoke from Claude Code with `/tayfa-init`, `/tayfa-onboard backend`,
etc., or let Claude pick the right one based on intent.

## CLI — core

```
tayfa-inbox <tag>     # tasks/bugs/memos addressed to @tag (incl. @all broadcasts); memos on dormant boards
                      # or dated >21 d ago go to a HISTORY footer (--all, --memo-days 0 restore them)
tayfa-ask <cmd>       # RETIRED 2026-09-11: agents talk to the usta in chat
tayfa-slack <cmd>     # optional Slack bridge: inbox mirror + usta<->agent convos
```

`@all` is a broadcast address: a memo with `**To:** @all` (or a
`### Tasks — @all` section) lands in **every** agent's inbox. An agent
acks an @all memo for itself by appending its own `#<tag>` to the To:
line; the memo is struck `~~` only when everyone relevant has acked.

**Aliases.** A project may give an agent a short second name in
`dev/coordination/aliases.json` (`{"kfe": "keyframe_editor"}`; keys
starting with `_` are comments). Every tool accepts either name and
resolves to the canonical one before touching a file: `/tayfa-onboard
kfe` registers `@keyframe_editor`, `tayfa-inbox keyframe_editor` also
lists work addressed to `@kfe`, `tayfa-ping kfe` lands in
`keyframe_editor`'s log. Matching is whole-tag, so `@kfe` never claims
`@kfe_polish`'s mail.

That's the whole essential surface area. `tayfa-inbox` walks up from
the current working directory looking for
`dev/coordination/AGENTS.md` and uses the directory it finds. Pass
`--coord-dir <path>` to override.

**Talking to the usta (the human) happens in chat.** An agent puts its
question or its review link in its reply, in its own session, and ends
its turn with it. The file inbox that used to carry this (`tayfa-ask`,
`dev/coordination/usta_inbox/`) was retired on 2026-09-11: in its
busiest project 1 of 126 questions filed through it was ever answered.
`tayfa-ask` is now a shim that says so and writes nothing.

The four core skills (`tayfa-init`, `tayfa-add-agent`,
`tayfa-add-workstream`, `tayfa-onboard`) plus the inbox CLI are all
you need to use tayfa. Stop here if that's all you want.

## Per-project switches: `dev/coordination/tayfa.json`

Optional. Every tool reads it tolerantly (missing file or key = the
tool's default), so each switch is undone by deleting one key:
`memo_stale_days` (inbox; 0 = off), `ping_fold_status` (ping --unread;
false = show all in full), plus whatever a project's own scripts add
(nima: `lane_cap_enforce`, `lane_active_days`, `state_max_words`).

## Presence, beats, and the roster ("tayfa pulse")

Presence registration is a **default step of the onboarding ritual**
(since 2026-07-08): each agent session registers its PID in
`dev/coordination/.presence/<tag>.json`. On top of that sit three
tools:

```
tayfa-roster                  # CLI: list awake agents (PID-validated)
tayfa-roster --serve          # loopback web roster on :8533 + /roster.json
tayfa-ping <tag> "<message>"  # tmux send-keys + log + notify (sender = --from, $TAYFA_TAG, or the calling session's registered tag)
tayfa-ping --status <tag> "…" # a status report, not an ask: readers see it as one line
tayfa-ping --unread <tag>     # pings since you last read, then mark read (status + @system folded to one line each; --full shows all)
tayfa-beat [--note "..."]     # heartbeat (usually fired by a Stop hook)
```

How it works:

- **Registration** — `register_presence.sh <tag>` (run by the
  `tayfa-onboard` ritual) records the session's PID, tty, and tmux
  target. Tag collisions with a live PID are refused.
- **Heartbeats** — install `tayfa-beat` as a **user-level Claude Code
  Stop hook** (`~/.claude/settings.json`) and every registered session
  writes `.presence/beats/<tag>.json` at the end of every turn — cron
  ticks included, no model cooperation required. One hook line serves
  every agent on the machine: tayfa-beat resolves *which* agent it is
  at runtime by matching its PID ancestry against the registry
  (`$TAYFA_TAG` overrides). It is strictly fail-soft: outside a tayfa
  project or in an unregistered session it silently exits 0.

  ```json
  "hooks": { "Stop": [ { "hooks": [ { "type": "command",
    "command": "/home/<you>/.local/bin/tayfa-beat",
    "async": true, "timeout": 10 } ] } ] }
  ```

  Agents can additionally run `tayfa-beat --note "tick 14 — waiting on
  review"` to publish a status line; the note persists across
  automatic beats until replaced.
- **The dashboard** — `tayfa-roster --serve [--port 8533]` is a
  zero-dependency loopback HTTP server: `/` (the roster,
  auto-refreshing) and `/roster.json` for machines (a future watchdog's
  input). (The `/inbox` page went with `tayfa-ask`, retired 2026-09-11.) All intra-page URLs are relative, so it works standalone or
  behind a reverse-proxy prefix (e.g. a project portal at `/s/roster/`). Status
  model: **AWAKE** (beat fresher than `--stale-after`, default 20 min),
  **QUIET** (session alive but no fresh beat — idle, or its cron/loop
  silently died and needs re-arming; this is the diagnostic the plain
  PID check can't give you), **GONE** (session ended; shown greyed for
  24 h). Optional per-project extra columns via
  `.presence/roster.conf.json` (shell command per tag, e.g. last
  `coord(<tag>)` commit). It binds `127.0.0.1` only — standalone in a
  browser, or front it with whatever LAN portal/reverse proxy the
  project already has.
- **Compaction survival** — a parachute file
  (`scratchboards/<tag>/inflight.md`, kept current while working: in-flight
  items, an `## armed` list of crons/wakeups, waiting-ons) plus two
  user-level hooks running `tayfa-compact`: **PreCompact** injects
  preserve-this-state guidance for the summarizer; **PostCompact** injects
  the re-entry ritual (read the parachute, re-arm crons — they die on
  compaction — check inbox, rewrite the parachute fresh). Both hooks
  self-heal the presence registry via session_id when a harness respawns
  the host process mid-session (stale-PID fix, shared with tayfa-beat).

  ```json
  "PreCompact":  [ { "hooks": [ { "type": "command",
    "command": "/home/<you>/.local/bin/tayfa-compact --pre",  "timeout": 10 } ] } ],
  "PostCompact": [ { "hooks": [ { "type": "command",
    "command": "/home/<you>/.local/bin/tayfa-compact --post", "timeout": 10 } ] } ]
  ```
- **Pings** — `tayfa-ping <tag>` always appends to
  `dev/coordination/.pings/<tag>.log`, plus `tmux send-keys` and
  `notify-send` when available. The log is permanent history, never
  rewritten. `tayfa-ping --unread <tag>` shows what arrived since the
  tag last read (newest 20 / 12k chars; older ones counted, with the
  `sed` line range to read them) and advances a byte cursor in
  `.pings/<tag>.cursor`; `--peek` reads without advancing. Registration
  runs it, and agents run it in their cron ticks instead of tailing the
  log. Where no tmux target exists (VSCode), this is the only way a
  live session receives a ping.

The `.presence/` and `.pings/` directories are gitignored
automatically by `tayfa-init` (older projects: add
`dev/coordination/.presence/` and `.pings/` to `.gitignore` — beats
churn every turn and must never hit git).

## Optional: the Slack bridge (`tayfa-slack`)

> **Dormant.** The item mirror below rode `tayfa-ask`, which was retired
> on 2026-09-11 (agents talk to the usta in chat). It never ran in
> production; the free-form convo half is the part still worth anything.

Mirrors the usta inbox into a Slack channel and routes replies back —
so the human can run the crew from their phone:

- **Item → channel.** New `tayfa-ask` items post as channel messages.
- **Thread reply → agent.** The human replies in the item's thread; the
  daemon writes it back onto the item — the first reply on an open
  question becomes its **answer** (`tayfa-ask check` picks it up), and
  the sending agent gets a real-time `tayfa-ping` nudge.
- **Agent reply → thread.** `tayfa-ask reply <id> --from <tag> --text
  "..."` is relayed into the same Slack thread. Items carry a full
  `thread` array; `tayfa-ask thread <id>` shows the conversation.
- **Free-form convos.** Top-level channel messages route to an agent's
  conversation log (`slack_convo/<tag>.jsonl`): a leading `@tag `
  routes explicitly, anything else goes to `default_agent` (usually
  the kalfa/PM). Agents read with `tayfa-slack pull <tag>` and reply
  with `tayfa-slack send --from <tag> "..."`.

Config at `dev/coordination/.slack.json` (gitignore it — it holds a
secret; also gitignore `.slack_state.json`, `.slack_daemon.lock`,
`slack_convo/`). Run `tayfa-slack status` to sanity-check, then
`tayfa-slack daemon` under screen/tmux. **Mode matters:** a plain
incoming *webhook* is SEND-ONLY (Slack returns no message ts, so thread
replies cannot be correlated back). For the full loop provide a **bot
token** (`xoxb-`, scopes `chat:write` + `channels:history` +
`channels:read`; private channels need `groups:*`) and the channel id,
and invite the bot to the channel. The daemon is a singleton per coord
dir (flock) and polls (default 20 s) — no public endpoint or Socket
Mode needed.

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
- **Roles** (optional, per project). A project may define a role as
  `dev/coordination/roles/<role>.md` (who gets it, what setup args it
  takes, what an agent in that role reads and does at onboard) plus an
  optional idempotent setup hook `roles/<role>.sh`. `add_agent.sh <tag>
  --role <role> [args]` records it in `scratchboards/<tag>/ROLE` and
  runs the hook; on an existing tag it attaches the role instead of
  refusing. `register_presence.sh` prints the role, `tayfa-onboard`
  step 5b sends the agent to the role file, and the post-compaction
  re-entry has it re-read. A role adds to the ritual, never replaces a
  step. Projects with no `roles/` directory see no change.
- **Per-agent skills** (optional, per agent). A procedure that only one
  agent runs lives in `scratchboards/<tag>/skills/<name>.md` (or
  `<name>/SKILL.md`) with Claude Code skill frontmatter: `name`, a
  one-line `description` that is the trigger, `owner`. It stays out of
  the shared skill directories, so no other session pays for it.
  `register_presence.sh` lists name + description, `tayfa-onboard` step
  5c says open one only when its trigger fires, and the post-compaction
  re-entry re-lists them. A few agents share one by symlink; when
  everyone needs it, it moves to the project's `.claude/skills/`
  unchanged. No `skills/` directory, no output.

The full conventions live in the scaffolded `README.md` and
`AGENTS.md` once you run `tayfa-init`.

## Layout

```
packages/tayfa/
├── README.md           ← you are here
├── install.sh
├── bin/
│   ├── tayfa-inbox     ← project-agnostic inbox tool
│   ├── tayfa-roster    ← dashboard: roster (CLI + --serve)
│   ├── tayfa-ask       ← RETIRED shim: tells agents to use chat
│   ├── tayfa-ping      ← real-time ping
│   ├── tayfa-beat      ← heartbeat (Stop-hook target)
│   ├── tayfa-compact   ← compaction parachute (Pre/PostCompact hook target)
│   └── tayfa-slack     ← Slack bridge (inbox mirror + convos)
├── skills/             ← Claude Code skills, one dir each
│   ├── tayfa-init/
│   ├── tayfa-add-agent/
│   ├── tayfa-add-workstream/
│   ├── tayfa-onboard/
│   └── tayfa-kalfa/       ← become the foreman / PM agent for the crew
└── templates/          ← markdown templates copied into projects
    ├── README.md.tmpl
    ├── AGENTS.md.tmpl
    ├── ONBOARDING.md.tmpl
    ├── workstream.md.tmpl
    └── scratchboard_main.md.tmpl
```
