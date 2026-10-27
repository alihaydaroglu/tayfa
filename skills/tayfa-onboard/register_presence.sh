#!/usr/bin/env bash
# tayfa: register the calling agent's session in .presence/<tag>.json.
#
# Called by the tayfa-onboard skill as the first step of the ritual.
# Refuses if <tag> is already registered with a live PID.
#
# Usage: register_presence.sh <tag> [--session-id <id>]
#
# Pass --session-id with your Claude Code session uuid (the last path
# component of your scratchpad directory) — PID-anchored identity breaks
# whenever the harness respawns the host process (constant under the
# VSCode extension), and the session id is the stable anchor the beat /
# compaction hooks fall back to (read-only).

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: register_presence.sh <tag> [--session-id <id>]" >&2
    exit 1
fi

TAG="${1#@}"
SESSION_ID_ARG=""
if [[ "${2:-}" == "--session-id" && -n "${3:-}" ]]; then
    SESSION_ID_ARG="$3"
fi

if [[ ! "$TAG" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "ERROR: tag must be alphanumeric + underscores (got: $TAG)" >&2
    exit 1
fi

# Walk up from cwd to find coord dir.
find_coord_dir() {
    local cur
    cur="$(pwd)"
    while [[ "$cur" != "/" ]]; do
        if [[ -f "$cur/dev/coordination/AGENTS.md" ]]; then
            echo "$cur/dev/coordination"
            return 0
        fi
        cur="$(dirname "$cur")"
    done
    return 1
}

if ! COORD_DIR="$(find_coord_dir)"; then
    echo "ERROR: could not find dev/coordination/AGENTS.md in any ancestor of $(pwd)." >&2
    exit 1
fi

# Tag aliases: <coord>/aliases.json maps short tags to canonical ones
# ({"kfe": "keyframe_editor"}). Resolve BEFORE anything is written, so the
# presence entry, beats, pings and scratchboard all live under the
# canonical name and the alias is just another way to say it.
CANON="$(python3 - "$COORD_DIR/aliases.json" "$TAG" <<'PYEOF'
import json, sys
path, tag = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path, encoding="utf-8"))
except (OSError, ValueError):
    data = {}
if not isinstance(data, dict):
    data = {}
print(str(data.get(tag, tag)).lstrip("@"))
PYEOF
)"
if [[ -n "$CANON" && "$CANON" != "$TAG" ]]; then
    echo "@$TAG is an alias of @$CANON ($COORD_DIR/aliases.json): registering as @$CANON."
    echo "  Use '$CANON' for the rest of the ritual — scratchboards/$CANON/, tayfa-inbox $CANON, the boards' @$CANON sections."
    TAG="$CANON"
fi

# Walk up from $PPID skipping transient shells to find the long-lived
# session process (typically the claude binary itself).
find_session_pid() {
    local pid=$PPID
    local depth=0
    while (( depth < 12 )); do
        [[ ! -r "/proc/$pid/comm" ]] && break
        local comm
        comm="$(cat "/proc/$pid/comm" 2>/dev/null || echo)"
        case "$comm" in
            bash|sh|zsh|dash|fish|ksh)
                local ppid
                ppid="$(awk '{print $4}' "/proc/$pid/stat" 2>/dev/null || echo)"
                if [[ -z "$ppid" || "$ppid" -le 1 ]]; then
                    break
                fi
                pid=$ppid
                ;;
            *)
                echo "$pid|$comm"
                return 0
                ;;
        esac
        ((depth++))
    done
    # Fallback: return $PPID even if it's a shell.
    local fallback_comm
    fallback_comm="$(cat "/proc/$PPID/comm" 2>/dev/null || echo unknown)"
    echo "$PPID|$fallback_comm"
}

SESSION_INFO="$(find_session_pid)"
SESSION_PID="${SESSION_INFO%|*}"
SESSION_COMM="${SESSION_INFO#*|}"

if ! kill -0 "$SESSION_PID" 2>/dev/null; then
    echo "ERROR: detected session PID $SESSION_PID is not alive — cannot register." >&2
    exit 1
fi

mkdir -p "$COORD_DIR/.presence"
PRESENCE_FILE="$COORD_DIR/.presence/$TAG.json"

# Duplicate-tag check: refuse if existing entry's PID is still alive AND is
# not our own. Under the VSCode extension the host process outlives the
# session: a RESUMED session has a new session id but the SAME pid, so
# it used to hit its own entry here and be refused — then its beats never
# attributed, the roster showed it asleep for hours, and the do-not-fight
# protocol told it to go quiet (@telemetry, tayfa_system.md 2026-09-05).
# A same-pid entry is never a rival; it is the same host coming back.
# (A same SESSION ID under a different live pid is NOT treated as a
# resume: forks share a session id, and that case stays a refusal.)
if [[ -f "$PRESENCE_FILE" ]]; then
    EXISTING_PID="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('pid',''))" "$PRESENCE_FILE" 2>/dev/null || echo)"
    if [[ -n "$EXISTING_PID" ]] && kill -0 "$EXISTING_PID" 2>/dev/null; then
        if [[ "$EXISTING_PID" == "$SESSION_PID" ]]; then
            EXISTING_SID="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('session_id') or '')" "$PRESENCE_FILE" 2>/dev/null || echo)"
            echo "@$TAG: this host (PID $SESSION_PID) is already registered under session ${EXISTING_SID:-?}."
            echo "  Same pid, new session: treating it as a RESUME and replacing the entry (not a duplicate)."
        else
            EXISTING_TTY="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('tty',''))" "$PRESENCE_FILE" 2>/dev/null || echo)"
            echo "ERROR: @$TAG is already registered (PID $EXISTING_PID, tty $EXISTING_TTY); this session is PID $SESSION_PID." >&2
            echo "       Pick a different tag, or end the other session first." >&2
            exit 2
        fi
    fi
    # Stale entry (dead pid) or our own resumed entry — replace it.
    rm -f "$PRESENCE_FILE"
fi

TTY_PATH="$(tty 2>/dev/null || echo)"
TMUX_TARGET=""
if [[ -n "${TMUX:-}" ]]; then
    # session_name:window_index.pane_index
    TMUX_TARGET="$(tmux display-message -p '#S:#I.#P' 2>/dev/null || echo)"
fi
SESSION_ID="${SESSION_ID_ARG:-${CLAUDE_SESSION_ID:-}}"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CWD="$(pwd)"

python3 - "$PRESENCE_FILE" <<PYEOF
import json, sys
out = {
    "tag": "$TAG",
    "pid": $SESSION_PID,
    "comm": "$SESSION_COMM",
    "tty": "$TTY_PATH" or None,
    "tmux_target": "$TMUX_TARGET" or None,
    "session_id": "$SESSION_ID" or None,
    "started_at": "$STARTED_AT",
    "cwd": "$CWD",
}
out = {k: v for k, v in out.items() if v is not None}
with open(sys.argv[1], "w") as f:
    json.dump(out, f, indent=2)
PYEOF

echo "Registered @$TAG → PID $SESSION_PID ($SESSION_COMM) at $PRESENCE_FILE"

# Roles: project-defined add-ons to the onboarding ritual (tayfa-onboard
# step 5b). Printed here too so a re-registration after compaction or a
# host respawn surfaces them again. First word of a line is the role.
ROLE_FILE="$COORD_DIR/scratchboards/$TAG/ROLE"
if [[ -s "$ROLE_FILE" ]]; then
    echo
    echo "── @$TAG has a role: read each role file now (tayfa-onboard step 5b) ──"
    while read -r role rest || [[ -n "${role:-}" ]]; do
        [[ -z "${role:-}" || "$role" == \#* ]] && continue
        echo "  $role${rest:+  ($rest)}  →  $COORD_DIR/roles/$role.md"
    done < "$ROLE_FILE"
fi

# Per-agent skills (tayfa-onboard step 5c): procedures that only this agent
# runs, kept out of the shared skill directories so no other session pays
# for them (@ali 2026-10-26, via @zepto: "i would like this reboot review to
# be a skill for you but i dont want it to be in the general md file").
# A skill is scratchboards/<tag>/skills/<name>.md or <name>/SKILL.md with a
# `name:` and a one-line `description:` in its frontmatter; the description
# is the trigger. Listed here by name + description only. The agent opens a
# skill when its trigger fires, never at onboard. No skills/ dir, no output.
SKILLS_DIR="$COORD_DIR/scratchboards/$TAG/skills"
if [[ -d "$SKILLS_DIR" ]]; then
    skill_files=()
    for f in "$SKILLS_DIR"/*.md "$SKILLS_DIR"/*/SKILL.md; do
        [[ -f "$f" ]] && skill_files+=("$f")
    done
    if (( ${#skill_files[@]} )); then
        echo
        echo "── @$TAG has ${#skill_files[@]} skill(s), yours alone: open one when its trigger fires, not now (tayfa-onboard step 5c) ──"
        for f in "${skill_files[@]}"; do
            awk -v path="$f" '
                NR==1 && $0 != "---" { exit }
                NR>1  && $0 == "---" { exit }
                /^name:/        { sub(/^name:[ \t]*/, "");        name=$0 }
                /^description:/ { sub(/^description:[ \t]*/, ""); desc=$0 }
                END {
                    if (name == "") {
                        n = split(path, parts, "/"); name = parts[n]; sub(/\.md$/, "", name)
                        if (name == "SKILL") name = parts[n-1]
                    }
                    gsub(/^["\047]|["\047]$/, "", desc)
                    if (length(desc) > 240) desc = substr(desc, 1, 237) "..."
                    if (desc == "") desc = "(no description: add one, it is the trigger)"
                    printf "  %s  →  %s\n      %s\n", name, path, desc
                }' "$f"
        done
    fi
fi

# Show the pings that arrived since this tag last read, and mark them read.
# The log is permanent history; tayfa-ping --unread keeps a cursor beside it
# and caps what it prints. Never let a ping problem fail the registration.
PING_LOG="$COORD_DIR/.pings/$TAG.log"
if [[ -s "$PING_LOG" ]]; then
    PING_TOOL="$(dirname "$(readlink -f "$0")")/../../bin/tayfa-ping"
    [[ -x "$PING_TOOL" ]] || PING_TOOL="$(command -v tayfa-ping || true)"
    echo
    if [[ -z "$PING_TOOL" ]] || ! "$PING_TOOL" --unread "$TAG" --coord-dir "$COORD_DIR"; then
        echo "── newest pings in $PING_LOG (tayfa-ping --unread unavailable) ──"
        tail -c 12000 "$PING_LOG" || true
        echo "──"
    fi
fi
