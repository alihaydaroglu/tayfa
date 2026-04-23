#!/usr/bin/env bash
# tayfa-add-workstream <slug> <title> — create dev/coordination/<slug>.md.

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: add_workstream.sh <slug> <title>" >&2
    echo "  e.g. add_workstream.sh webapp 'Webapp Stack'" >&2
    exit 1
fi

SLUG="$1"
TITLE="$2"

if [[ ! "$SLUG" =~ ^[a-z0-9_-]+$ ]]; then
    echo "ERROR: slug must be lowercase alphanumeric + hyphens/underscores (got: $SLUG)" >&2
    exit 1
fi

if [[ "$SLUG" == "README" || "$SLUG" == "AGENTS" || "$SLUG" == "ONBOARDING" ]]; then
    echo "ERROR: slug '$SLUG' is reserved." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
TAYFA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES="$TAYFA_ROOT/templates"

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

DEST="$COORD_DIR/$SLUG.md"

if [[ -e "$DEST" ]]; then
    echo "ERROR: $DEST already exists." >&2
    exit 1
fi

# sed escape: TITLE may contain & or / — use a delimiter unlikely in title text.
ESCAPED_TITLE="${TITLE//|/\\|}"
sed "s|{{TITLE}}|$ESCAPED_TITLE|g" "$TEMPLATES/workstream.md.tmpl" > "$DEST"

echo "Created $DEST"
echo
echo "Now add a row to $COORD_DIR/README.md under ## Workstreams:"
echo "  | [$SLUG.md]($SLUG.md) | <one-line scope> | Active — opened $(date +%Y-%m-%d) |"
