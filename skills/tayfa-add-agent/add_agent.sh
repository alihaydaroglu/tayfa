#!/usr/bin/env bash
# tayfa-add-agent <tag> — create scratchboards/<tag>/main.md from template.
#
# Walks up from cwd looking for dev/coordination/AGENTS.md to find the
# coord dir.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: add_agent.sh <tag>" >&2
    echo "  e.g. add_agent.sh backend" >&2
    exit 1
fi

TAG="${1#@}"

if [[ ! "$TAG" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "ERROR: tag must be alphanumeric + underscores (got: $TAG)" >&2
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

DEST_DIR="$COORD_DIR/scratchboards/$TAG"
DEST="$DEST_DIR/main.md"

if [[ -e "$DEST_DIR" ]]; then
    echo "ERROR: $DEST_DIR already exists." >&2
    exit 1
fi

mkdir -p "$DEST_DIR"
sed "s/{{TAG}}/$TAG/g" "$TEMPLATES/scratchboard_main.md.tmpl" > "$DEST"

echo "Created $DEST"
echo
echo "Now add a row to $COORD_DIR/AGENTS.md:"
echo "  | @$TAG | <role> | [$TAG/main.md](scratchboards/$TAG/main.md) | <workstreams> |"
