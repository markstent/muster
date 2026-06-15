# Muster

**A structured development system for Claude Code.** Seven commands take you
from a half-formed idea to a merged pull request, with you in control at every
gate.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2)](https://claude.com/claude-code)
[![Last commit](https://img.shields.io/github/last-commit/markstent/muster)](https://github.com/markstent/muster/commits/main)
[![Open issues](https://img.shields.io/github/issues/markstent/muster)](https://github.com/markstent/muster/issues)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/markstent/muster/pulls)

*Muster* (verb): to assemble and prepare a force for action. The system musters
your ideas into specs, your specs into tasks, and a fleet of sub-agents into
reviewed, shippable code — and never moves without your say-so.

---

## What it does

Muster is built on two ideas borrowed from disciplined engineering practice and
wired into a two-tier agent loop:

1. **Plan before you code.** Most agent failures aren't the model writing bad
   code — they're requirements that were never fully specified. Muster forces a
   grilling session and a written spec before a single line is written.
2. **Separate deciding from doing.** A read-only Manager agent decides what is
   safe to build; a Worker coordinator builds it, proves it with tests, reviews
   its own diffs, and waits for your approval before opening a PR.

Nothing is ever auto-merged. You are the merge gate, always.

---

## The seven commands

| Command | Phase | Role | What it does |
|---|---|---|---|
| `/think` | Plan | You + agent | Interrogates your idea until every decision branch is resolved |
| `/context` | Plan | Agent | Builds and maintains `CONTEXT.md` — shared domain memory |
| `/spec` | Plan | Agent | Writes a spec issue + vertical-slice task issues on GitHub |
| `/triage` | Manage | **Manager** | State machine: classifies, assesses risk, routes work |
| `/build` | Execute | **Worker coordinator** | Spawns sub-agents, builds with TDD, auto-reviews, waits for you |
| `/review` | Review | Agent | Two-axis review (Standards + Spec) before you merge |
| `/status` | Any time | Agent | Snapshot of the whole pipeline and what to do next |

> **Command names.** Installed as a plugin, the commands are namespaced:
> `/muster:think`, `/muster:build`, and so on (no collisions with your own
> commands). Installed via the symlink script, they are the bare names shown
> above. This README uses the bare names for readability.

---

## Installation

### Prerequisites

- [Claude Code](https://claude.com/claude-code) installed
- [GitHub CLI](https://cli.github.com/) installed and authenticated:
  ```bash
  gh auth login
  ```
- A git remote pointing at GitHub

### Option A — plugin (recommended)

Inside Claude Code:

```
/plugin marketplace add markstent/muster
/plugin install muster@muster
```

Commands appear as `/muster:think`, `/muster:spec`, and so on. Update later
from the `/plugin` menu.

### Option B — symlink (bare command names)

Clone and symlink the commands into `~/.claude/commands/` so they are available
globally as `/think`, `/spec`, etc.:

```bash
curl -fsSL https://raw.githubusercontent.com/markstent/muster/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/markstent/muster.git ~/.muster
mkdir -p ~/.claude/commands
ln -sf ~/.muster/commands/*.md ~/.claude/commands/
```

Update with `git -C ~/.muster pull`.

### First-time repo setup (both options)

Create the GitHub labels Muster uses, once per repo:

```bash
bash ~/.muster/setup-labels.sh
```

(If you installed via the plugin, run `setup-labels.sh` from a clone of this
repo — it only needs `gh` authenticated against the target repo.)

---

## The flow

```
new idea
   |
   v
/think        resolve the idea, one question at a time, recommended answers
   |
/context      run once per repo; refresh when major concepts change
   |
/spec         spec issue + task issues (vertical slices) on GitHub
   |             tasks labelled: task + ready
   v
/triage       MANAGER AGENT (read-only on code)
   |             state machine: bug/enhancement + one of
   |             needs-triage / needs-info / agent-ready /
   |             needs-human-input / wontfix
   |             risk gate: low / medium / high
   |             high risk never becomes agent-ready
   |
   |  agent-ready tasks only
   v
/build        WORKER COORDINATOR
   |             max 3 tasks per run (burnout cap)
   |             groups by independence -> parallel where safe
   |             spawns Worker sub-agents (TDD: vertical slices, one
   |               test -> one impl, behaviour not implementation)
   |             verifies: tests pass, scope respected, branch clean
   |             AUTO inner review, two parallel axes:
   |               Standards (conventions + security) and Spec (does it
   |               match the issue?)
   |             rejected -> needs-work, never reaches you
   |             presents full summary -> waits for your terminal approval
   |             approve -> PR opened (never auto-merged)
   |             reject  -> sent back with your reason as an issue comment
   |
   v
/review       optional final two-axis check on any PR
   |
   v
you merge     always manual, always yours
   |
   v
/status       check what's left, what's next
```

---

## Two-tier agent architecture

```
            +----------------------------------+
            |          MANAGER AGENT           |
            |             /triage              |
            |  reads codebase + CONTEXT.md     |
            |  writes labels + comments only   |
            |  classifies, assesses risk,      |
            |  routes. Never touches code.     |
            +----------------+-----------------+
                             | agent-ready tasks
                             v
            +----------------------------------+
            |       WORKER COORDINATOR         |
            |             /build               |
            |  spawns Worker sub-agents (TDD)  |
            |  verifies results                |
            |  fires two-axis inner review     |
            |  waits for your approval         |
            |  opens PRs (never merges)        |
            +----------------+-----------------+
                             | approved diffs
                             v
                     PR opened — you merge
```

---

## Label system

| Label | Set by | Meaning |
|---|---|---|
| `spec` | /spec | Parent spec issue |
| `task` | /spec | A buildable unit of work |
| `ready` | /spec | Awaiting triage |
| `bug` | /triage | Category: something is broken |
| `enhancement` | /triage | Category: new feature or improvement |
| `needs-triage` | /triage | Awaiting evaluation |
| `needs-info` | /triage | Waiting on you for detail |
| `agent-ready` | /triage | Cleared for /build to execute |
| `needs-human-input` | /triage | Needs your implementation or decision |
| `wontfix` | /triage | Will not be actioned |
| `risk:low` / `risk:medium` / `risk:high` | /triage | Risk assessment |
| `on-hold` | /build | Skipped by you during a medium-risk pause |
| `in-review` | /build | PR is open, awaiting your merge |
| `needs-work` | /build or /review | Rejected — needs changes |
| `blocked` | /build | Sub-agent hit an unresolvable problem |

Create them all in one go:

```bash
bash setup-labels.sh
```

---

## A worked example

```
You:  /think
      I want a rate limiter for my API.
Muster: [asks about algorithm, storage, scope, limits, what's out of scope,
         one question at a time, recommending an answer each time]
You:  [answer until it summarises and you confirm]

You:  /context        (first time in this repo)
Muster: [writes CONTEXT.md with your stack and domain terms]

You:  /spec
Muster: [writes spec issue #12, then task issues #13, #14, #15 — each a
         vertical slice with a test seam and scope boundary]

You:  /triage
Muster: [reads the code, classifies each task, assigns risk, posts an agent
         brief on the low/medium ones, routes a schema change to
         needs-human-input because it's high risk]

You:  /build
Muster: [shows the execution plan: #13 and #14 can run in parallel, #15 waits]
You:  yes
Muster: [spawns Workers, each writes a failing test then code then refactors,
         runs a two-axis inner review, then:]
        BATCH COMPLETE — AWAITING YOUR APPROVAL
        [+] #13  risk:low  add token bucket  Standards PASS · Spec PASS
        [+] #14  risk:low  add limiter middleware  Standards PASS · Spec PASS
You:  13            (inspect the diff)
You:  approve all
Muster: [opens PR for #13 and #14, linked to spec #12]

You:  /review 13
Muster: [final two-axis check, SAFE TO MERGE]
You:  [merge on GitHub]

You:  /status
Muster: [#15 still needs-human-input; one spec in progress]
```

---

## Design decisions

**You approve every task before its PR opens.** The build loop always stops and
waits. You can inspect the full diff, approve, reject, or stop entirely.

**The Manager never touches code.** `/triage` has read-only access to the
codebase and writes only labels and comments. Deciding and doing are separated
so a routing mistake can't become a code mistake.

**Risk gates autonomy.** High-risk work (schema, auth, public API, security)
never reaches the autonomous loop. Medium-risk work pauses for you. Low-risk
work flows.

**TDD in vertical slices.** Workers write one test, make it pass, then move on —
never all tests up front, which produces tests of imagined rather than actual
behaviour. Tests target behaviour through public interfaces, so they survive
refactors.

**Two-axis review.** Code is checked separately for conventions (Standards) and
for matching the issue (Spec). A change can pass one and fail the other; keeping
them apart stops one masking the other.

**CONTEXT.md is the shared brain.** Every command reads it, so sub-agents speak
your domain language and respect your prior decisions.

**Three caps stop runaway loops.** Triage handles at most 10 issues per run;
build handles at most 3 tasks per run with at most 3 concurrent Workers.

---

## Project layout

```
.claude-plugin/
  plugin.json        plugin manifest
  marketplace.json   makes this repo its own single-plugin marketplace
commands/
  think.md     -> /think
  context.md   -> /context
  spec.md      -> /spec
  triage.md    -> /triage
  build.md     -> /build
  review.md    -> /review
  status.md    -> /status
setup-labels.sh      create the GitHub labels (once per repo)
install.sh           non-plugin install (clone + symlink commands)
README.md
CONTRIBUTING.md
LICENSE

# Generated at your repo root by /context:
CONTEXT.md
```

---

## Credit and lineage

The planning and review philosophy draws on
[Matt Pocock's skills for real engineers](https://github.com/mattpocock/skills) —
specifically the grilling approach (`/think`), the triage state machine and
agent-ready routing (`/triage`), vertical-slice TDD (`/build`), two-axis review
(`/review`), and the spec-as-source-of-truth idea (`/spec`). The two-tier
Manager/Worker orchestration, the risk-gated autonomous loop, the burnout caps,
and the terminal approval gates are Muster's own.

If you want the original, broader skill set (handoff, diagnose, prototype,
zoom-out, and more), install Pocock's directly — Muster is a focused,
opinionated subset wired for autonomous building.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT. See [LICENSE](LICENSE).
