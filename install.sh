#!/usr/bin/env bash
#
# install.sh - install Muster as Agent Skills for Claude Code (the non-plugin path).
#
# This clones Muster to ~/.muster and symlinks each skill into
# ~/.claude/skills/, so the commands are available globally as
# /think, /spec, /build, ... in Claude Code. Re-run to update: it pulls first.
#
# Prefer the plugin instead? See the README:
#   /plugin marketplace add markstent/muster
#   /plugin install muster@muster
#
# Using a different harness (Cursor, Codex, Gemini CLI, ...)? Muster ships as
# standard Agent Skills - copy the skills/ tree into that tool's skills
# directory. See the README "Other harnesses" section.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/markstent/muster/main/install.sh | bash

set -euo pipefail

REPO="https://github.com/markstent/muster.git"
SRC="${MUSTER_HOME:-$HOME/.muster}"
DEST="$HOME/.claude/skills"

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

echo "Linking skills into $DEST ..."
linked=0
for skill in "$SRC"/skills/*/; do
  name="$(basename "$skill")"
  ln -sfn "$skill" "$DEST/$name"
  linked=$((linked + 1))
done

echo "Linked $linked skills."
echo
echo "Done. Open any repo in Claude Code and type / to see:"
echo "  /think  /context  /spec  /triage  /build  /review  /status"
echo
echo "Per repo, create the GitHub labels once:"
echo "  bash $SRC/setup-labels.sh"
