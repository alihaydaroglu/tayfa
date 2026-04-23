#!/usr/bin/env bash
# tayfa: register the calling agent's session in .presence/<tag>.json.
#
# Called by the tayfa-onboard skill as the first step of the ritual.
# Refuses if <tag> is already registered with a live PID.
#
# Usage: register_presence.sh <tag>

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: register_presence.sh <tag>" >&2
    exit 1
fi

TAG="${1#@}"

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

# Duplicate-tag check: refuse if existing entry's PID is still alive.
if [[ -f "$PRESENCE_FILE" ]]; then
    EXISTING_PID="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('pid',''))" "$PRESENCE_FILE" 2>/dev/null || echo)"
    if [[ -n "$EXISTING_PID" ]] && kill -0 "$EXISTING_PID" 2>/dev/null; then
        EXISTING_TTY="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('tty',''))" "$PRESENCE_FILE" 2>/dev/null || echo)"
        echo "ERROR: @$TAG is already registered (PID $EXISTING_PID, tty $EXISTING_TTY)." >&2
        echo "       Pick a different tag, or end the other session first." >&2
        exit 2
    fi
    # Stale entry — remove silently.
    rm -f "$PRESENCE_FILE"
fi

TTY_PATH="$(tty 2>/dev/null || echo)"
TMUX_TARGET=""
if [[ -n "${TMUX:-}" ]]; then
    # session_name:window_index.pane_index
    TMUX_TARGET="$(tmux display-message -p '#S:#I.#P' 2>/dev/null || echo)"
fi
SESSION_ID="${CLAUDE_SESSION_ID:-}"
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

# Surface any pings logged while this tag was offline.
PING_LOG="$COORD_DIR/.pings/$TAG.log"
if [[ -s "$PING_LOG" ]]; then
    echo
    echo "── Pings waiting for you in $PING_LOG ──"
    cat "$PING_LOG"
    echo "──"
    echo "(Move or truncate the log once you've handled them.)"
fi
