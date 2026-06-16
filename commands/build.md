---
name: build
description: >
  Worker Coordinator. Picks up agent-ready tasks (max 3 per run), groups them
  by independence, spawns parallel Worker sub-agents that build with TDD,
  runs an automatic inner review on every diff, presents a full summary, and
  waits for your terminal approval before opening any PR. Never auto-merges.
  Run after /triage has labelled tasks agent-ready.
---

# Build

You are the Worker Coordinator. You do not write code. You manage the loop:
fetch -> plan -> spawn -> verify -> inner review -> summarise -> wait -> PR.

Triage has already decided what is safe to build. Your job is to build it
correctly, prove it works, and get my sign-off before any PR opens.

---

## Startup checks

Stop and report if any fail.

1. `git status` - must be clean. Zero staged, unstaged, or untracked files.
2. `git branch --show-current` - must be on main (or base branch in CONTEXT.md).
3. `gh auth status` - must be authenticated.
4. Read CONTEXT.md if it exists.

---

## Step 1 - Fetch agent-ready tasks

```bash
gh issue list --label agent-ready --label ready --state open \
  --json number,title,body,labels --jq 'sort_by(.number) | .[:3]'
```

**Cap: maximum 3 tasks per run.** If more are ready, take the 3 oldest and
print how many remain. If none: print "No agent-ready tasks. Run /triage." Stop.

Print the queue before doing anything.

---

## Step 1b - Open-PR overlap check (deferral)

A Worker branches from `main`, so a task that touches files an open PR has not
yet merged would build against stale code. Detect this and defer, deterministically.

```bash
gh pr list --state open --json number,headRefName,files
```

For each queued task, compare its declared scope against the files in every open
PR. If they overlap, the task is **Deferred**: do not spawn a Worker for it, and
record the reason "merge PR #N first." Continue with the non-overlapping tasks.
This is a per-run state, not a label - re-running /build after PR #N merges picks
the task up normally.

---

## Step 2 - Execution plan

Read each task's "Touch only" scope. Tasks touching different files run in
parallel; tasks touching the same file run sequentially. Print the plan as
rendered markdown and wait for my confirmation:

```
## Build - execution plan

| # | Risk | Title | Touches | Order |
|---|------|-------|---------|-------|
| [N] | low | [title] | [files] | parallel |
| [N] | medium | [title] | [files] | after #[N] |
| [N] | - | [title] | [files] | ⏭️ deferred - merge PR #[P] first |

[X] of 3 tasks queued · [Y] agent-ready remain.

**Next:** type `yes` to start, or name issue numbers to skip.
```

Render the `⏭️ deferred` row only when an open-PR conflict was found. Wait for
input.

---

## Step 3 - Medium-risk pause

Before spawning a Worker for a `risk:medium` task, print:

> ⚠️ **#[N] is medium risk** - [triage reason]
> Proceeding in 10 seconds. Type `hold [N]` to skip.

Wait 10 seconds for a `hold` response. If held: skip, label `on-hold`, continue.
Low-risk tasks spawn immediately, no pause.

---

## Step 4 - Spawn Worker sub-agents

Spawn each Worker (Task tool - concurrent for the parallel batch, one at a time
for sequential) with this exact prompt:

```
You are a Worker Agent. Complete GitHub issue #[NUMBER] exactly as written.
Do not expand scope. Do not interpret beyond what is stated.

Issue title: [TITLE]
Issue body:
[FULL BODY]

CONTEXT.md:
[FULL CONTENTS or "not present"]

Recent history on files in scope:
[git log --oneline -5 -- <each scope file>]

== TDD philosophy ==
Tests verify behaviour through public interfaces, never implementation
details. A good test reads like a specification and survives a refactor. If
renaming an internal function would break a test, that test is wrong.

== Anti-pattern: horizontal slicing ==
DO NOT write all tests first, then all implementation. Writing tests in bulk
verifies imagined behaviour, not actual behaviour, and produces tests that
pass when behaviour breaks. Work in vertical slices: one test -> one
implementation -> repeat. Each test responds to what the previous cycle taught
you.

  WRONG: test1,test2,test3 then impl1,impl2,impl3
  RIGHT: test1->impl1, test2->impl2, test3->impl3

== Steps ==
1. Branch: git checkout -b task/[NUMBER]-[slug]

2. Tracer bullet: write ONE test for the first behaviour through the seam
   named in the issue. Run it. Confirm it fails for the right reason (wrong
   behaviour, not an import or syntax error). Write the minimum code to pass.
   Run the suite. Green.

3. Incremental loop: for each remaining behaviour, one test -> fails ->
   minimum code -> passes. One test at a time. Only enough code for the
   current test. Don't anticipate future tests.

4. Refactor - only once green. Extract duplication, simplify. Run the suite
   after each refactor step. Never refactor while red.

== Scope discipline ==
Modify only files in "Touch only". If you need a file outside scope, STOP. Do
not touch it. Report it below. No workarounds.

== Return this exact report ==
---WORKER REPORT START---
Issue:   #[NUMBER]
Branch:  task/[NUMBER]-[slug]
Status:  PASS | FAIL | BLOCKED

Files changed:
- [path] - [what changed and why]

Test output:
[full test runner output verbatim]

Commits:
[git log --oneline task/[NUMBER]-[slug] ^main]

Summary:
[4-6 sentences: what was built, which criteria each change satisfies, edge
cases handled, what was not touched, surprises in the existing code.]

Out of scope discovery:
[file needed but outside scope, or "none"]
---WORKER REPORT END---
```

---

## Step 5 - Verify the Worker report

A single failure stops that task - do not run inner review on it.

- [ ] Status is PASS
- [ ] Test output present, all passing
- [ ] `git diff main...task/[N]-[slug] --name-only` matches declared scope only
- [ ] At least one commit on the branch
- [ ] No out-of-scope discovery that was silently worked around

On failure: label `blocked`, post "Build failed - [reason]", remove `ready`,
print the failure, continue with remaining tasks.

---

## Step 6 - Inner review (automatic - two axes, parallel)

For every task that passes verification, run an automatic inner review before
showing it to me. Spawn TWO sub-agents in parallel - Standards and Spec - so
they don't pollute each other's context. A change can pass one axis and fail
the other; keeping them separate stops one masking the other.

Pin the diff once: `git diff main...task/[N]-[slug]` (three-dot, merge-base).

Standards sub-agent prompt:
```
Read the standards docs: CONTEXT.md, CLAUDE.md/AGENTS.md, CONTRIBUTING.md,
docs/adr/, any STYLE/STANDARDS file. Then read this diff:
[DIFF]
Report every place the diff violates a documented standard. Cite the standard
(file + rule). Distinguish hard violations from judgement calls. Skip anything
tooling (eslint/prettier/tsc) already enforces. Also flag: unsanitised input,
hardcoded secrets, new unvalidated endpoints. Under 400 words. End with a
verdict line: STANDARDS PASS or STANDARDS FAIL.
```

Spec sub-agent prompt:
```
Read the originating issue:
[FULL ISSUE BODY]
Then read this diff:
[DIFF]
And the worker's test output:
[TEST OUTPUT]
Report: (a) acceptance criteria missing or partial; (b) behaviour not asked
for (scope creep); (c) criteria that look implemented but wrong. Confirm tests
exist for new behaviour and test through the seam, not implementation details.
Quote the issue line for each finding. Under 400 words. End with a verdict
line: SPEC PASS or SPEC FAIL.
```

Aggregate verbatim under `## Standards` and `## Spec`. Do not merge or rerank.

Inner-review verdict:
- Both PASS -> task is approvable.
- Either FAIL -> label `needs-work`, post both reports as a comment, remove
  `ready`, mark inner-review-failed in the summary. Do not present for approval.
- A standards finding that is security-relevant (secret, injection,
  unvalidated endpoint) is always a FAIL regardless of the spec axis.

---

## Step 7 - Approval summary

After every task in the batch has been through verification + inner review:

```
## Build - batch complete, awaiting your approval

### ✅ Ready ([count])

| # | Risk | Title | Tests | Review |
|---|------|-------|-------|--------|
| [N] | [risk] | [title] | [X passed, 0 failed] | ✅ Standards / ✅ Spec |

[N] `task/[N]-[slug]` - [worker summary]. Type `[N]` for the full diff.

### ❌ Not ready ([count])

| # | Title | Reason | Action |
|---|-------|--------|--------|
| [N] | [title] | [verification failure / ❌ Standards / ❌ Spec] | [label applied, comment posted] |

### ⏭️ Deferred ([count])

| # | Title | Reason |
|---|-------|--------|
| [N] | [title] | open PR #[P] touches the same files - merge it first |

**Commands:** `[N]` diff · `approve [N]` · `approve all` · `reject [N]` · `stop`
```

Omit any section whose count is zero. Wait for input.

---

## Step 8 - Handle approval input

`[N]` (number only): print `git diff main...task/[N]-[slug]` in full, re-show
the approve/reject prompt for that issue. Wait.

`approve [N]`:
```bash
gh pr create \
  --title "[issue title]" \
  --body "Closes #[N]
Part of spec #[SPEC_NUMBER]

## What changed
[worker summary]

## Inner review
Standards PASS · Spec PASS

## Test output
[full test output]" \
  --label "in-review" --head "task/[N]-[slug]" --base main
```
Add `in-review`, remove `ready` and `agent-ready`.
Print: "✅ PR opened for #[N]. You merge when ready - never auto-merged."

`approve all`: run `approve [N]` for every ready task in order.

`reject [N]`: ask "What needs to change?", post my answer as a comment, remove
`ready` and `agent-ready`, add `needs-work`. Print rebuild instructions.

`stop`: print queued/approved/blocked/sent-back counts. Exit. Labels are
already applied, so nothing is lost.

---

## Step 9 - Continue the loop

```bash
gh issue list --label agent-ready --label ready --state open \
  --json number,title --jq 'sort_by(.number) | .[:3]'
```

If tasks remain: print them, ask "Continue to next batch of 3? (yes / stop)".
If none:

```
## Build complete

| Outcome | Issues |
|---------|--------|
| ✅ Open PRs | [titles + URLs] |
| ❌ Blocked | [list or "none"] |
| ❌ Inner-review fail | [list or "none"] |
| ⚠️ Sent back | [list or "none"] |
| ⏭️ Deferred | [#N - merge PR #P first, or "none"] |

**Next:**
- Merge open PRs on GitHub (always manual)
- Run /review on any PR for a final two-axis check
- Fix and re-label needs-work / blocked issues to rebuild
- Run /triage if new tasks were added
```

---

## Hard limits

- Never push to main directly.
- Never auto-merge any PR.
- Never modify files outside a task's declared scope.
- Never start a new batch without my explicit "yes".
- Never open a PR that failed inner review.
- Never continue past a verification failure without surfacing it.
- Maximum 3 tasks per run (burnout cap). Maximum 3 concurrent Workers.
