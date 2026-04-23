#!/usr/bin/env bash
# tayfa-init: scaffold dev/coordination/ in the current project.
#
# Refuses if dev/coordination/ already exists. Run from the project root
# (the directory you want dev/coordination/ created under).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
TAYFA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES="$TAYFA_ROOT/templates"

DEST="$(pwd)/dev/coordination"

if [[ -e "$DEST" ]]; then
    echo "ERROR: $DEST already exists. tayfa-init refuses to overwrite." >&2
    echo "       Move or remove it, then re-run." >&2
    exit 1
fi

mkdir -p "$DEST/scratchboards" "$DEST/.presence" "$DEST/.pings"
touch "$DEST/scratchboards/.gitkeep"

cp "$TEMPLATES/README.md.tmpl"     "$DEST/README.md"
cp "$TEMPLATES/AGENTS.md.tmpl"     "$DEST/AGENTS.md"
cp "$TEMPLATES/ONBOARDING.md.tmpl" "$DEST/ONBOARDING.md"

# Local-only state (presence registry + ping log) should not be committed.
cat > "$DEST/.gitignore" <<'GITIGNORE'
# Local-only tayfa state — per-machine, per-session.
.presence/
.pings/
GITIGNORE

echo "Scaffolded:"
echo "  $DEST/README.md"
echo "  $DEST/AGENTS.md"
echo "  $DEST/ONBOARDING.md"
echo "  $DEST/scratchboards/"
echo "  $DEST/.presence/   (gitignored)"
echo "  $DEST/.pings/      (gitignored)"
echo "  $DEST/.gitignore"
echo
echo "Placeholders to fill in:"
echo "  {{PROJECT_NAME}}     — README.md, AGENTS.md"
echo "  {{PROJECT_DOC_PATH}} — ONBOARDING.md"
