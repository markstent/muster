---
name: spec
description: >
  Turn the current conversation into a spec issue and task issues on GitHub.
  Run after /think resolves the idea, or directly when the idea is already
  concrete. Do not re-interview — synthesise what you already know.
---

# Spec

Convert a resolved idea into a parent spec issue and child task issues on GitHub.
Work from the conversation. Do not re-interview me. If something critical is
genuinely missing, ask one targeted question, then continue.

## Step 1 — Read the codebase

- Read CONTEXT.md if it exists. Use its domain glossary vocabulary throughout
  the spec. Respect any ADRs in the area you're touching.
- Run `git log --oneline -10`
- Identify which files or modules this spec will likely touch

## Step 2 — Sketch the test seams

Before writing the spec, sketch the seams at which the feature will be tested.
Prefer existing seams to new ones. Use the highest seam possible — test through
the broadest public interface that still isolates the behaviour. If new seams
are needed, propose them at the highest point you can, and check with me that
they match my expectations.

## Step 3 — Create the spec issue

Use `gh issue create` with label `spec`:

```
Title: spec: [plain-language name]

## Problem
[The problem I'm facing, from my perspective. One paragraph.]

## Solution
[The solution, from my perspective. What, not how. 2-4 sentences.]

## Test seams
[Where this will be tested, and why those seams.]

## Done when
- [ ] [Concrete, independently verifiable criterion]

## Out of scope
- [Explicit non-goal from the /think session]

## Touches
- [file or module]
```

Save the spec issue number as $SPEC_NUMBER.

## Step 4 — Create task issues

Break the spec into independently-grabbable issues using vertical slices
(tracer bullets). A tracer bullet cuts through every layer — it is a thin,
complete, shippable behaviour, not a horizontal "all the frontend" or "all the
backend" slice. Each task must be completable without another task in this
batch being finished first. If a task depends on another finishing, recut.

For each task, use `gh issue create` with labels `task` and `ready`:

```
Title: [verb] [specific thing] (spec #$SPEC_NUMBER)

## What
[1-2 sentences. The behaviour this slice delivers.]

## Why
[Which done-criterion from the spec this satisfies.]

## Acceptance criteria
- [ ] [Specific and testable. Name files, functions, or behaviours.]
- [ ] Tests written for all new behaviour, through the seam from the spec
- [ ] Full test suite passes

## Scope
Touch only: [specific files or modules]
Do not touch: [everything else]
```

Use the project's domain glossary vocabulary in titles and descriptions.

## Step 5 — Link and summarise

Comment on the spec issue listing all child task numbers, then print:

```
Spec:  #[N] — [title]
Tasks:
  #[N] [title]
  #[N] [title]
Ready to run /triage
```

## Rules

- Write the spec before any tasks.
- Vertical slices only. Never a horizontal layer-by-layer split.
- Never create a task that depends on another task finishing — recut instead.
- Labels only: `spec`, `task`, `ready`. No assignees, milestones, or projects.
- If `gh` is not authenticated: stop and print "Run: gh auth login".
