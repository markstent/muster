#!/usr/bin/env bash
#
# install.sh - install Muster as plain slash commands (the non-plugin path).
#
# This clones Muster to ~/.muster and symlinks its commands into
# ~/.claude/commands/, so they are available globally as bare commands
# (/think, /spec, /build, ...). Re-run to update: it pulls the latest first.
#
# Prefer the plugin instead? See the README:
#   /plugin marketplace add markstent/muster
#   /plugin install muster@muster
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/markstent/muster/main/install.sh | bash

set -euo pipefail

REPO="https://github.com/markstent/muster.git"
SRC="${MUSTER_HOME:-$HOME/.muster}"
DEST="$HOME/.claude/commands"

if ! command -v git >/dev/null 2>&1; then
  echo "git not found. Install git and try again." >&2
  exit 1
fi

# Clone or update.
if [ -d "$SRC/.git" ]; then
  echo "Updating Muster in $SRC ..."
  git -C "$SRC" pull --ff-only
else
  echo "Cloning Muster to $SRC ..."
  git clone "$REPO" "$SRC"
fi

mkdir -p "$DEST"

echo "Linking commands into $DEST ..."
linked=0
for cmd in "$SRC"/commands/*.md; do
  name="$(basename "$cmd")"
  ln -sf "$cmd" "$DEST/$name"
  linked=$((linked + 1))
done

echo "Linked $linked commands."
echo
echo "Done. Open any repo in Claude Code and type / to see:"
echo "  /think  /context  /spec  /triage  /build  /review  /status"
echo
echo "Per repo, create the GitHub labels once:"
echo "  bash $SRC/setup-labels.sh"
