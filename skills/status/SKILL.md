---
name: status
disable-model-invocation: true
description: >
  A quick snapshot of where everything stands - your specs, every task grouped
  by status, open PRs, recent activity, and what to do next. Run any time to get
  your bearings. Reads only; changes nothing.
---

# Status

Print where this project stands right now and what to do next. This command is
strictly read-only: it fetches issues, PRs, and git state and reports them. It
never changes a label, comment, branch, or file.

## Step 1 - Preconditions

- `gh auth status` - if not authenticated, print "Run: gh auth login" and stop.
- Read `CONTEXT.md` if it exists (for the base branch and domain vocabulary).

## Step 2 - Gather

Fetch in parallel where possible:

```bash
gh issue list --label spec  --state open --json number,title,labels
gh issue list --label task  --state all  --json number,title,labels,updatedAt
gh pr list --state open --json number,title,headRefName,labels
git log --oneline -10
```

## Step 3 - Bucket the tasks

Sort each task into exactly one bucket by its state label. A task with no state
label sits in "awaiting triage". Within each bucket, oldest first.

- **Awaiting triage** - `ready` without `agent-ready`/`needs-human-input`, or no state label
- **Agent-ready** - `agent-ready` (show the `risk:*` label)
- **Needs you** - `needs-human-input`
- **Needs info** - `needs-info`
- **In review** - `in-review` (link the open PR)
- **Needs work** - `needs-work`
- **On hold** - `on-hold`
- **Blocked** - `blocked`
- **Done** - closed in the last 7 days

## Step 4 - Print the snapshot

```
## Muster status

Here's where everything stands right now.

**Specs (open)**

| Spec | Title | Tasks |
|------|-------|-------|
| #[N] | [title] | [X tasks: Y done, Z open] |

### Where the tasks are

| Status | Count | Issues |
|--------|-------|--------|
| Awaiting triage | [n] | #[N] [title] |
| ✅ Agent-ready | [n] | #[N] (risk:[risk]) [title] |
| ⚠️ Needs you | [n] | #[N] [title] |
| ⚠️ Needs info | [n] | #[N] [title] |
| In review | [n] | #[N] [title] -> PR #[P] |
| ⚠️ Needs work | [n] | #[N] [title] |
| ⏭️ On hold | [n] | #[N] [title] |
| ❌ Blocked | [n] | #[N] [title] |
| ✅ Done (7d) | [n] | #[N] [title] |

(Agent-ready = ready for me to build on my own · Needs you = needs a person ·
In review = a PR is open, waiting for you to merge.)

### Open PRs

| PR | Title | Branch |
|----|-------|--------|
| #[P] | [title] | [branch] - waiting for you to merge |

### Recent commits on [base]

[git log --oneline -10, as a fenced code block]

**Next:** [the one or two things most worth doing - see below.]
```

Omit any pipeline row whose count is zero. Render the commit log inside a fenced
code block (it is literal output); everything else is rendered markdown.

## Step 5 - Prioritise "Next"

Recommend the highest-leverage action, in this order:

1. Open PRs waiting on you → "Merge PR #P (or run /review P first)."
2. `agent-ready` tasks with nothing in review → "Run /build."
3. `ready`/untriaged tasks → "Run /triage."
4. `needs-info`/`needs-human-input` → name what you owe each one.
5. `needs-work`/`blocked` → "Fix and re-label `ready`, then /triage."
6. No open specs at all → "Run /think then /spec to start something."

Give the one or two actions that matter most, not the whole list.

## Rules

- Read-only. Never change a label, comment, branch, PR, or file.
- Every task appears in exactly one bucket.
- If `gh` is unauthenticated, stop after the precondition check.
