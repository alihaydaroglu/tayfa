#!/usr/bin/env bash
# tayfa-add-agent <tag> [--role <role> [setup args...]]
#
# Creates scratchboards/<tag>/main.md from template.
#
# --role <role> gives the agent a project-defined ROLE. A role is
#   dev/coordination/roles/<role>.md   what an agent in that role reads and
#                                      does at onboard (required)
#   dev/coordination/roles/<role>.sh   one-time setup, run here as
#                                      `bash <role>.sh <tag> [setup args...]`
#                                      (optional; must be idempotent)
# The role is recorded as a line in scratchboards/<tag>/ROLE. tayfa-onboard
# (step 5b) and register_presence.sh read that file. Only the first word of
# a line is the role; a setup hook may append detail after it.
#
# Passing --role for a tag that already exists ATTACHES the role to that
# agent instead of refusing, and re-runs the setup hook.
#
# Walks up from cwd looking for dev/coordination/AGENTS.md to find the
# coord dir.

set -euo pipefail

usage() {
    echo "Usage: add_agent.sh <tag> [--role <role> [setup args...]]" >&2
    echo "  e.g. add_agent.sh backend" >&2
    echo "       add_agent.sh mira_ad --role director mira_ad \"the brief\"" >&2
    exit 1
}

[[ $# -ge 1 ]] || usage
TAG="${1#@}"; shift
ROLE=""
if [[ $# -gt 0 ]]; then
    [[ "$1" == "--role" && -n "${2:-}" ]] || usage
    ROLE="$2"; shift 2
fi
SETUP_ARGS=("$@")

if [[ ! "$TAG" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "ERROR: tag must be alphanumeric + underscores (got: $TAG)" >&2
    exit 1
fi
if [[ -n "$ROLE" && ! "$ROLE" =~ ^[a-z0-9_-]+$ ]]; then
    echo "ERROR: role must be [a-z0-9_-] (got: $ROLE)" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
TAYFA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES="$TAYFA_ROOT/templates"

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
    echo "       Run tayfa-init first, or cd into a tayfa-initialised project." >&2
    exit 1
fi

ROLES_DIR="$COORD_DIR/roles"
if [[ -n "$ROLE" && ! -f "$ROLES_DIR/$ROLE.md" ]]; then
    echo "ERROR: this project defines no role '$ROLE' ($ROLES_DIR/$ROLE.md is missing)." >&2
    if compgen -G "$ROLES_DIR/*.md" >/dev/null; then
        echo "       roles here: $(cd "$ROLES_DIR" && ls ./*.md | sed 's|^\./||; s/\.md$//' | tr '\n' ' ')" >&2
    fi
    exit 1
fi

DEST_DIR="$COORD_DIR/scratchboards/$TAG"
DEST="$DEST_DIR/main.md"

CREATED=0
if [[ -e "$DEST_DIR" ]]; then
    if [[ -z "$ROLE" ]]; then
        echo "ERROR: $DEST_DIR already exists." >&2
        echo "       (to give an existing agent a role: add_agent.sh $TAG --role <role> ...)" >&2
        exit 1
    fi
    echo "@$TAG already exists; attaching role '$ROLE'."
else
    mkdir -p "$DEST_DIR"
    sed "s/{{TAG}}/$TAG/g" "$TEMPLATES/scratchboard_main.md.tmpl" > "$DEST"
    CREATED=1
    echo "Created $DEST"
fi

if [[ -n "$ROLE" ]]; then
    ROLE_FILE="$DEST_DIR/ROLE"
    touch "$ROLE_FILE"
    if ! awk '{print $1}' "$ROLE_FILE" | grep -qx -- "$ROLE"; then
        echo "$ROLE" >> "$ROLE_FILE"
    fi
    echo "Role '$ROLE' recorded in $ROLE_FILE"

    HOOK="$ROLES_DIR/$ROLE.sh"
    if [[ -f "$HOOK" ]]; then
        echo "Running role setup: $HOOK $TAG ${SETUP_ARGS[*]:-}"
        if ! COORD_DIR="$COORD_DIR" bash "$HOOK" "$TAG" ${SETUP_ARGS[@]+"${SETUP_ARGS[@]}"}; then
            echo "ERROR: role setup failed. @$TAG and its ROLE line are in place;" >&2
            echo "       fix the args and re-run: add_agent.sh $TAG --role $ROLE <args>" >&2
            echo "       (the role file says what its setup needs: $ROLES_DIR/$ROLE.md)" >&2
            exit 3
        fi
    fi
fi

if (( CREATED )); then
    echo
    echo "Now add a row to $COORD_DIR/AGENTS.md:"
    echo "  | @$TAG | <role> | [$TAG/main.md](scratchboards/$TAG/main.md) | <workstreams> |"
fi
if [[ -n "$ROLE" ]]; then
    echo
    echo "At onboard, @$TAG reads $ROLES_DIR/$ROLE.md (tayfa-onboard step 5b)."
fi
