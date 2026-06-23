---
name: spec
disable-model-invocation: true
description: >
  (Muster) Turn the agreed idea into a written spec and a set of small, buildable tasks -
  saved as one file you can edit - then create the GitHub issues once you say go.
  Run after /think, or straight away if the idea is already clear. Won't
  re-interview you.
---

# Spec

Convert a resolved idea into one spec file, then - on your say-so - into a parent
spec issue and child task issues on GitHub. Work from the conversation; do not
re-interview me. If something critical is genuinely missing, ask one targeted
question, then continue.

The spec file is the source of truth. You write it once, I edit it in my editor,
and only then do you create issues from it. Create nothing on GitHub until I reply
`create`.

## Step 1 - Read the codebase

- Read CONTEXT.md if it exists. Use its domain glossary vocabulary throughout.
  Respect any ADRs in the area you're touching.
- Run `git log --oneline -10`.
- Identify which files or modules this spec will likely touch.

## Step 2 - Sketch the test points

Sketch the points at which the feature will be tested. Prefer existing test points
to new ones. Use the broadest public interface that still isolates the behaviour.
If new test points are needed, propose them at the highest level you can and check
they match my expectations.

## Step 3 - Write the spec file (create no issues yet)

Compose the spec and every task into ONE markdown file. Derive the path:

```bash
mkdir -p docs/specs
# slug = kebab-case of the spec title; date = $(date +%F)
# file = docs/specs/<date>-<slug>.md
```

Write this structure to the file. Do NOT print its contents back into the chat -
just write it.

```
# Spec: <plain-language name>

## Problem
<the problem, from my perspective. One paragraph.>

## Solution
<what, not how. 2-4 sentences.>

## User stories
<a focused numbered list - "As an <actor>, I want <feature>, so that <benefit>".
 Cover the feature's real paths, not every edge; keep it tight. These are what
 the automatic review and /triage check the work against.>
1. As a <actor>, I want <feature>, so that <benefit>.

## Test points
<where this will be tested, and why those test points. Name prior art - similar
 tests already in the codebase - so the Worker follows an existing pattern.>

## Done when
- [ ] <concrete, independently verifiable criterion>

## Out of scope
- <explicit non-goal from the /think session>

## Touches
- <file or module>

---

## Tasks

### Task 1 - <verb> <specific thing>
**Type:** AFK | HITL  <AFK = an agent can build and merge it unattended; HITL =
needs a human decision or review. A hint only; /triage makes the binding call.>
**What:** <1-2 sentences. The behaviour this slice delivers.>
**Why:** <which done-criterion from the spec this satisfies.>
**Covers:** <which user-story numbers this slice satisfies.>
**Acceptance:**
- [ ] <specific and testable. Name files, functions, or behaviours.>
- [ ] Tests written for all new behaviour, through the test point above
- [ ] Full test suite passes
**Scope:** touch only <files/modules>; do not touch <everything else>

### Task 2 - <verb> <specific thing>
...
```

Content discipline:
- Acceptance criteria must be concrete and independently testable - name files,
  functions, or observable behaviours, not "works correctly".
- Use the project's domain glossary vocabulary in every title and body.
- Problem and Solution stay what-not-how.
- User stories stay from the actor's perspective, not implementation steps.
- `Type` (AFK/HITL) is a hint to speed triage, not a routing decision. Prefer
  AFK; mark HITL only when a human decision, design review, or high-risk surface
  is genuinely involved. /triage confirms or overrides it.
- No code snippets in the body. Exception: if a prototype produced a snippet
  that encodes a decision more precisely than prose can (a state machine, schema,
  or type shape), inline just the decision-rich part and note it came from a
  prototype - never a working demo.
- Each task is a vertical slice (a tracer bullet cutting through every layer), not
  a horizontal "all the frontend" / "all the backend" split. No task may depend on
  another in this batch finishing first - if one does, recut.
- Slice independence check: before writing the file, compare every task's `Scope`.
  Two tasks must not touch the same file. If they do, recut so they are
  file-disjoint. If you genuinely cannot make them disjoint, keep them but add a
  line `> Note: must follow Task N (touches the same files; cannot build in
  parallel)` under the later task, and flag it at the review gate. Same-file
  slices cannot build autonomously side by side: the later one needs the earlier
  PR merged first, which is a manual step the pipeline will not do for you.

## Step 4 - Review gate

Print the slice breakdown so I can sanity-check the cut before any issue exists,
then wait:

```
## Spec - ready for your review

Here's how I'd split the work into tasks. Take a look before I create anything
on GitHub - it's all written to `docs/specs/<file>` (<N> tasks).

| # | Title | Who | Files |
|---|-------|-----|-------|
| 1 | <title> | auto | <files> |
| 2 | <title> | needs you | <files> |

("auto" = I can build and merge it on my own · "needs you" = needs a human
decision or review. /triage makes the final call.)

A few things worth checking:
- Are the tasks the right size - any too big, any too small?
- Should any be combined, or split apart?
- Is the "Who" right on each one?

Edit the file directly to adjust, then reply `create` to make the issues, or
`cancel` to stop (your edits to the file are kept).
```

If any tasks change the same files, append this line before waiting:

```
⚠️ Heads-up: tasks <a> and <b> change the same files, so they can't be built at
the same time - the second one has to wait for the first to be merged. Consider
combining them into one task, or carry on knowing you'll merge them in order.
```

`cancel` → print "Nothing created." and stop. The file stays on disk for later.

## Step 5 - Generate issues (only after `create`)

Re-read the file first so my edits are honoured. Then:

1. Create the spec issue with `gh issue create`, label `spec`. Body = the spec
   section (Problem / Solution / User stories / Test points / Done when / Out of
   scope / Touches), ending with a line: `Spec file: docs/specs/<file>`. Save the
   number as `$SPEC_NUMBER`.
2. For each `### Task` in the file, create an issue with labels `task` and `ready`.
   Title: `<task title> (spec #$SPEC_NUMBER)`. Body = that task's Type / What /
   Why / Covers / Acceptance / Scope.
3. Comment on the spec issue listing every child task number.
4. Commit just the spec file (keeps the tree clean for /build):
   ```bash
   git add docs/specs/<file>
   git commit -m "spec: <title> (#$SPEC_NUMBER)"
   ```

Narrate tersely as you go: `Created spec #N`, `Created #N`.

## Step 6 - Summarise

```
## Spec created

Done - the spec and its tasks are now issues on GitHub.

**Spec #N** - <title> · <N> tasks · `docs/specs/<file>` committed

**Next:** run /triage
```

## Rules

- Create nothing on GitHub until I reply `create`.
- Re-read the spec file at create time - my edits are the source of truth.
- One combined file per spec. Vertical slices only; never a horizontal split.
- Never create a task that depends on another task finishing - recut instead.
- Labels only: `spec`, `task`, `ready`. No assignees, milestones, or projects.
- If `gh` is not authenticated: stop and print "Run: gh auth login".
