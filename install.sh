#!/usr/bin/env bash
# Symlink tayfa skills into ~/.claude/skills/ and bin/tayfa-inbox into
# ~/.local/bin/. Symlinks let edits to packages/tayfa/ take effect without
# re-installing.
#
# Idempotent: replaces existing tayfa-* symlinks but refuses to overwrite
# real files / non-tayfa symlinks.

set -euo pipefail

TAYFA_ROOT="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SKILLS_SRC="$TAYFA_ROOT/skills"
BIN_SRC="$TAYFA_ROOT/bin"

SKILLS_DST="$HOME/.claude/skills"
BIN_DST="$HOME/.local/bin"

mkdir -p "$SKILLS_DST"

link_one() {
    local src="$1" dst="$2"
    if [[ -L "$dst" ]]; then
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        echo "ERROR: $dst exists and is not a symlink — refusing to overwrite." >&2
        return 1
    fi
    ln -s "$src" "$dst"
    echo "  linked $dst -> $src"
}

echo "Installing tayfa skills into $SKILLS_DST"
for skill_dir in "$SKILLS_SRC"/*/; do
    name="$(basename "$skill_dir")"
    link_one "${skill_dir%/}" "$SKILLS_DST/$name"
done

echo
if [[ -d "$BIN_DST" ]]; then
    echo "Installing tayfa CLIs into $BIN_DST"
    for tool in tayfa-inbox tayfa-roster tayfa-ping; do
        link_one "$BIN_SRC/$tool" "$BIN_DST/$tool"
    done
    if ! echo ":$PATH:" | grep -q ":$BIN_DST:"; then
        echo
        echo "  NOTE: $BIN_DST is not on your PATH. Add this to your shell rc:"
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
else
    echo "Skipping CLI install — $BIN_DST does not exist."
    echo "Either create it (mkdir -p $BIN_DST) and re-run, or manually add"
    echo "  $BIN_SRC"
    echo "to your PATH."
fi

echo
echo "Done."
