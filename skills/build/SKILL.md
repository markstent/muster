---
name: build
disable-model-invocation: true
description: >
  Builds the tasks triage marked ready - up to 3 at a time. Writes them
  test-first, double-checks each one against your conventions and against what
  the issue asked for, shows you everything, and waits for your OK before
  opening any PR. Never merges on its own. Run after /triage.
---

# Build

You coordinate the builders - you don't write code yourself. You run the loop:
pick up the ready tasks, plan them, hand each to a builder, check the result,
give it a quick automatic review, show me what's ready, and wait for my OK
before opening any PR.

Triage has already decided what's safe to build. Your job is to build it
correctly, prove it works, and get my sign-off before any PR opens.

---

## Startup checks

Stop and report if any fail.

1. `git status` - must be clean. Zero staged, unstaged, or untracked files.
2. `git branch --show-current` - must be on main (or base branch in CONTEXT.md).
3. `gh auth status` - must be authenticated.
4. Read CONTEXT.md if it exists.
5. Resolve the test command from CONTEXT.md (`## Stack` -> `Test command:`). If
   none can be resolved, stop: "Cannot verify tests - CONTEXT.md has no test
   command. Run /context to add one." Step 5 re-runs this command to gate every
   task, so the build cannot proceed without it.

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
## Build - here's the plan

I'm about to build [X] task(s). Ones that don't share files run together; the
rest wait their turn.

| # | Title | Files | When |
|---|-------|-------|------|
| [N] | [title] | [files] | now (low risk) |
| [N] | [title] | [files] | after #[N] (medium risk) |
| [N] | [title] | [files] | ⏭️ waiting - merge PR #[P] first |

[X] of 3 queued · [Y] more ready for later.

**Your move:** type `yes` to start, or list any numbers you'd rather skip.
```

Render the `⏭️ waiting` row only when an open-PR conflict was found. Wait for
input.

---

## Step 3 - Medium-risk pause

Before spawning a Worker for a `risk:medium` task, print:

> ⚠️ **#[N] is a bigger change** (medium risk) - [triage reason]
> I'll start it in 10 seconds. Type `hold [N]` if you'd rather I skip it for now.

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

2. Tracer bullet: write ONE test for the first behaviour through the test point
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

Re-run the tests yourself - do not trust the Worker's pasted output. Check out
the branch in an isolated tree (`git worktree add ../verify-[N] task/[N]-[slug]`,
or stash and `git checkout` if no worktree), run the canonical test command from
CONTEXT.md, capture its exit status and output, then remove the worktree (or
restore the prior branch and stash). Your re-run is the authority for the test
gate below; the Worker's pasted output is only cross-checked against it.

- [ ] Status is PASS
- [ ] Coordinator re-ran the suite on `task/[N]-[slug]` - exit status clean, all
      passing (this is the authority, not the Worker's pasted output)
- [ ] Worker's pasted test output matches the re-run (no fabrication / no stale paste)
- [ ] `git diff main...task/[N]-[slug] --name-only` matches declared scope only
- [ ] At least one commit on the branch
- [ ] No out-of-scope discovery that was silently worked around

On failure: label `blocked`, post "Build failed - [reason]" (use "tests fail on
re-run" or "worker test output did not match re-run" for the test-gate cases),
remove `ready`, print the failure, continue with remaining tasks.

---

## Step 6 - Inner review (automatic - two tracks, parallel)

For every task that passes verification, run an automatic inner review before
showing it to me. Spawn TWO sub-agents in parallel - Standards and Spec - so
they don't pollute each other's context. A change can pass one track and fail
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
exist for new behaviour and test through the test point, not implementation details.
Quote the issue line for each finding. Under 400 words. End with a verdict
line: SPEC PASS or SPEC FAIL.
```

Aggregate verbatim under `## Standards` and `## Spec`. Do not merge or rerank.

Inner-review verdict:
- Both PASS -> task is approvable.
- Either FAIL -> label `needs-work`, post both reports as a comment, remove
  `ready`, mark inner-review-failed in the summary. Do not present for approval.
- A standards finding that is security-relevant (secret, injection,
  unvalidated endpoint) is always a FAIL regardless of the spec track.

---

## Step 7 - Approval summary

After every task in the batch has been through verification + inner review:

```
## Build - done, and waiting for you

[N] task(s) are built and checked. Here's what's ready for you to look at.

### ✅ Ready ([count])

| # | Risk | Title | Tests | Checks |
|---|------|-------|-------|--------|
| [N] | [risk] | [title] | [X passed, 0 failed] | ✅ conventions / ✅ matches the issue |

[N] `task/[N]-[slug]` - [worker summary]. Type `[N]` to see the full diff.

### ❌ Not ready ([count])

| # | Title | What happened | What I did |
|---|-------|---------------|------------|
| [N] | [title] | [tests failed / ❌ conventions / ❌ doesn't match the issue] | [label applied, comment posted] |

### ⏭️ Waiting ([count])

| # | Title | Why |
|---|-------|-----|
| [N] | [title] | open PR #[P] changes the same files - merge it first |

**Your move:**
- `[N]` - show me the full diff for task N
- `approve [N]` / `approve all` - open the PR(s) (I never merge)
- `reject [N]` - send it back; I'll ask what needs to change
- `stop` - pause here; nothing is lost
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

## Checks
Conventions: passed · Matches the issue: passed

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
| ❌ Didn't pass review | [list or "none"] |
| ⚠️ Sent back | [list or "none"] |
| ⏭️ Waiting | [#N - merge PR #P first, or "none"] |

**Next:**
- Merge the open PRs on GitHub (always your call)
- Run /review on any PR for one more check before merging
- Fix and re-label needs-work / blocked issues, then build again
- Run /triage if new tasks came in
```

---

## Hard limits

- Never push to main directly.
- Never auto-merge any PR.
- Never modify files outside a task's declared scope.
- Never start a new batch without my explicit "yes".
- Never open a PR that failed inner review.
- Never continue past a verification failure without surfacing it.
- Maximum 3 tasks per run, and at most 3 builders at once, so nothing runs away.
