#!/usr/bin/env bash
#
# setup-labels.sh - create the GitHub labels Muster uses.
# Run once per repo where you use Muster. Safe to re-run: --force updates
# existing labels instead of failing.
#
# Requires: gh (authenticated) and a GitHub remote on the current repo.

set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) not found. Install it: https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

label() {
  # label <name> <color> <description>
  gh label create "$1" --color "$2" --description "$3" --force
}

echo "Creating Muster labels..."

# Structural - set by /spec
label spec              0075ca "Parent spec issue"
label task              e4e669 "A buildable unit of work"
label ready             0e8a16 "Awaiting triage"

# Category - set by /triage (exactly one per issue)
label bug               d73a4a "Category: something is broken"
label enhancement       a2eeef "Category: new feature or improvement"

# State - set by /triage (exactly one per issue)
label needs-triage      fbca04 "Awaiting evaluation"
label needs-info        fef2c0 "Waiting on you for more detail"
label agent-ready       006b75 "Cleared for /build to execute"
label needs-human-input e99695 "Needs your implementation or decision"
label wontfix           ffffff "Will not be actioned"

# Risk - set by /triage (gates agent-ready)
label risk:low          c2e0c6 "Risk: contained to a single file or module"
label risk:medium       fbca04 "Risk: spans files or touches shared utilities"
label risk:high         b60205 "Risk: architecture, schema, auth, or public API"

# Build / review lifecycle - set by /build and /review
label on-hold           cccccc "Skipped by you during a medium-risk pause"
label in-review         5319e7 "PR is open, awaiting your merge"
label needs-work        d93f0b "Rejected - needs changes"
label blocked           b60205 "Sub-agent hit an unresolvable problem"

echo "Done. Muster labels are ready in this repo."
