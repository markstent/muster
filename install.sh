#!/usr/bin/env bash
#
# install.sh - install Muster's skills into every Agent Skills harness on this
# machine, from a single clone.
#
# What it does:
#   1. Clones Muster to ~/.muster (or updates it if already there).
#   2. Detects which harnesses you have (Claude Code, Vibe, Codex, Gemini,
#      Cursor) and symlinks the seven skills into each one's skills directory.
#   3. Because they're symlinks to one clone, a later `git -C ~/.muster pull`
#      updates every harness at once - no re-copying.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/markstent/muster/main/install.sh | bash
#
#   # only specific harnesses (creates their dirs even if not detected):
#   bash install.sh claude vibe
#
#   # copy the files instead of symlinking (no single source of truth):
#   MUSTER_COPY=1 bash install.sh
#
# Prefer the Claude Code plugin? See the README:
#   /plugin marketplace add markstent/muster
#   /plugin install muster@muster

set -euo pipefail

REPO="https://github.com/markstent/muster.git"
SRC="${MUSTER_HOME:-$HOME/.muster}"
COPY="${MUSTER_COPY:-0}"

if ! command -v git >/dev/null 2>&1; then
  echo "git not found. Install git and try again." >&2
  exit 1
fi

# --- 1. Clone or update -----------------------------------------------------
if [ -d "$SRC/.git" ]; then
  echo "Updating Muster in $SRC ..."
  git -C "$SRC" pull --ff-only
else
  echo "Cloning Muster to $SRC ..."
  git clone "$REPO" "$SRC"
fi

# --- Known harnesses: "name|config-dir|skills-dir" --------------------------
# A harness is "detected" when its config-dir exists. skills-dir is where it
# reads SKILL.md folders from.
HARNESSES="
claude|$HOME/.claude|$HOME/.claude/skills
vibe|$HOME/.vibe|$HOME/.vibe/skills
codex|$HOME/.codex|$HOME/.codex/skills
gemini|$HOME/.gemini|$HOME/.gemini/skills
cursor|$HOME/.cursor|$HOME/.cursor/skills
"

# Link (or copy) every skill in the clone into a target skills directory.
install_into() {
  name="$1"; dir="$2"
  mkdir -p "$dir"
  count=0
  for skill in "$SRC"/skills/*/; do
    target="$dir/$(basename "$skill")"
    if [ "$COPY" = "1" ]; then
      rm -rf "$target"
      cp -R "$skill" "$target"
    else
      ln -sfn "$skill" "$target"
    fi
    count=$((count + 1))
  done
  verb="linked"; [ "$COPY" = "1" ] && verb="copied"
  echo "  $verb $count skills into $dir  ($name)"
}

# --- 2. Decide which harnesses to install into ------------------------------
# Args override detection: `install.sh claude vibe` installs into exactly those.
wanted="$*"
installed=0

echo
echo "Installing skills ..."
while IFS='|' read -r name config dir; do
  [ -z "$name" ] && continue
  if [ -n "$wanted" ]; then
    case " $wanted " in *" $name "*) ;; *) continue ;; esac   # only requested
  else
    [ -d "$config" ] || continue                              # only detected
  fi
  install_into "$name" "$dir"
  installed=$((installed + 1))
done <<EOF
$HARNESSES
EOF

if [ "$installed" -eq 0 ]; then
  echo "  No known harness detected."
  echo "  Run again naming yours, e.g.:  bash install.sh claude"
  echo "  Supported: claude vibe codex gemini cursor"
  echo "  Other harness? Point its skills dir at the clone yourself:"
  echo "    cp -R $SRC/skills/* <that-tool's-skills-dir>/"
fi

# --- 3. Done ----------------------------------------------------------------
echo
echo "Done. Reload your harness, then type / to see:"
echo "  /think  /context  /spec  /triage  /build  /review  /status"
echo
echo "Per repo, create the GitHub labels once:"
echo "  bash $SRC/setup-labels.sh"
