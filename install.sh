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
mkdir -p "$BIN_DST"
echo "Installing tayfa CLIs into $BIN_DST"
for tool in tayfa-inbox tayfa-roster tayfa-ping tayfa-beat tayfa-ask tayfa-slack tayfa-compact; do
    link_one "$BIN_SRC/$tool" "$BIN_DST/$tool"
done
if ! echo ":$PATH:" | grep -q ":$BIN_DST:"; then
    echo
    echo "  NOTE: $BIN_DST is not on your PATH. On Ubuntu a login shell picks it"
    echo "  up automatically now that it exists (re-login or: exec \$SHELL -l)."
    echo "  Otherwise add to your shell rc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo
echo "Wiring tayfa hooks into $HOME/.claude/settings.json"
python3 - "$BIN_DST" <<'PYEOF'
import json, os, shutil, sys

bin_dst = sys.argv[1]
path = os.path.expanduser("~/.claude/settings.json")

settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)   # corrupt JSON -> loud failure, no clobber

hooks = settings.setdefault("hooks", {})

WANTED = {
    "PostCompact":      {"type": "command", "command": f"{bin_dst}/tayfa-compact --post",   "timeout": 10},
    "UserPromptSubmit": {"type": "command", "command": f"{bin_dst}/tayfa-compact --prompt", "timeout": 10},
    "Stop":             {"type": "command", "command": f"{bin_dst}/tayfa-beat",             "timeout": 10, "async": True},
}

changed = False
for event, hook in WANTED.items():
    entries = hooks.setdefault(event, [])
    tool = os.path.basename(hook["command"].split()[0])
    existing = [h.get("command", "") for e in entries for h in e.get("hooks", [])]
    if any(tool in cmd for cmd in existing):
        print(f"  {event}: {tool} already wired — skipping")
        continue
    entries.append({"hooks": [hook]})
    changed = True
    print(f"  {event}: added {hook['command']}")

if changed:
    if os.path.exists(path):
        shutil.copy2(path, path + ".bak")
        print(f"  (previous settings backed up to {path}.bak)")
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
else:
    print("  all hooks already present — settings.json untouched")
PYEOF

echo
echo "Done."
