#!/usr/bin/env bash
# Install tayfa-codex skills and CLIs with symlinks.

set -euo pipefail

TAYFA_ROOT="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SKILLS_SRC="$TAYFA_ROOT/skills"
BIN_SRC="$TAYFA_ROOT/bin"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DST="$CODEX_HOME_DIR/skills"
BIN_DST="${TAYFA_BIN_DIR:-$HOME/.local/bin}"

mkdir -p "$SKILLS_DST" "$BIN_DST"

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

echo "Installing tayfa-codex skills into $SKILLS_DST"
for skill_dir in "$SKILLS_SRC"/*/; do
    name="$(basename "$skill_dir")"
    link_one "${skill_dir%/}" "$SKILLS_DST/$name"
done

echo
echo "Installing tayfa-codex CLIs into $BIN_DST"
for tool in tayfa-inbox tayfa-ask; do
    link_one "$BIN_SRC/$tool" "$BIN_DST/$tool"
done

if ! echo ":$PATH:" | grep -q ":$BIN_DST:"; then
    echo
    echo "NOTE: $BIN_DST is not on PATH. Add it to your shell configuration."
fi

echo
echo "Done. Start Codex in a new task so it discovers the installed skills."
