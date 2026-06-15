---
name: spec
description: >
  Turn the resolved idea into a spec. Drafts the spec and all task slices into a
  single markdown file under docs/specs/, lets you edit it, then generates the
  GitHub issues from the file on your confirmation. Run after /think, or directly
  when the idea is already concrete. Does not re-interview.
---

# Spec

Convert a resolved idea into one spec file, then — on your say-so — into a parent
spec issue and child task issues on GitHub. Work from the conversation; do not
re-interview me. If something critical is genuinely missing, ask one targeted
question, then continue.

The spec file is the source of truth. You write it once, I edit it in my editor,
and only then do you create issues from it. Create nothing on GitHub until I reply
`create`.

## Step 1 — Read the codebase

- Read CONTEXT.md if it exists. Use its domain glossary vocabulary throughout.
  Respect any ADRs in the area you're touching.
- Run `git log --oneline -10`.
- Identify which files or modules this spec will likely touch.

## Step 2 — Sketch the test seams

Sketch the seams at which the feature will be tested. Prefer existing seams to new
ones. Use the highest seam possible — the broadest public interface that still
isolates the behaviour. If new seams are needed, propose them at the highest point
you can and check they match my expectations.

## Step 3 — Write the spec file (create no issues yet)

Compose the spec and every task into ONE markdown file. Derive the path:

```bash
mkdir -p docs/specs
# slug = kebab-case of the spec title; date = $(date +%F)
# file = docs/specs/<date>-<slug>.md
```

Write this structure to the file. Do NOT print its contents back into the chat —
just write it.

```
# Spec: <plain-language name>

## Problem
<the problem, from my perspective. One paragraph.>

## Solution
<what, not how. 2-4 sentences.>

## Test seams
<where this will be tested, and why those seams.>

## Done when
- [ ] <concrete, independently verifiable criterion>

## Out of scope
- <explicit non-goal from the /think session>

## Touches
- <file or module>

---

## Tasks

### Task 1 — <verb> <specific thing>
**What:** <1-2 sentences. The behaviour this slice delivers.>
**Why:** <which done-criterion from the spec this satisfies.>
**Acceptance:**
- [ ] <specific and testable. Name files, functions, or behaviours.>
- [ ] Tests written for all new behaviour, through the seam above
- [ ] Full test suite passes
**Scope:** touch only <files/modules>; do not touch <everything else>

### Task 2 — <verb> <specific thing>
...
```

Content discipline:
- Acceptance criteria must be concrete and independently testable — name files,
  functions, or observable behaviours, not "works correctly".
- Use the project's domain glossary vocabulary in every title and body.
- Problem and Solution stay what-not-how.
- Each task is a vertical slice (a tracer bullet cutting through every layer), not
  a horizontal "all the frontend" / "all the backend" split. No task may depend on
  another in this batch finishing first — if one does, recut.

## Step 4 — Review gate

Print only this, then wait:

```
Spec written to docs/specs/<file> — <N> tasks.
Review and edit it directly, then reply: `create` to generate the issues, or `cancel`.
```

`cancel` → print "Nothing created." and stop. The file stays on disk for later.

## Step 5 — Generate issues (only after `create`)

Re-read the file first so my edits are honoured. Then:

1. Create the spec issue with `gh issue create`, label `spec`. Body = the spec
   section (Problem / Solution / Test seams / Done when / Out of scope / Touches),
   ending with a line: `Spec file: docs/specs/<file>`. Save the number as
   `$SPEC_NUMBER`.
2. For each `### Task` in the file, create an issue with labels `task` and `ready`.
   Title: `<task title> (spec #$SPEC_NUMBER)`. Body = that task's What / Why /
   Acceptance / Scope.
3. Comment on the spec issue listing every child task number.
4. Commit just the spec file (keeps the tree clean for /build):
   ```bash
   git add docs/specs/<file>
   git commit -m "spec: <title> (#$SPEC_NUMBER)"
   ```

Narrate tersely as you go: `Created spec #N`, `Created #N`.

## Step 6 — Summarise

```
## Spec created

**Spec #N** — <title> · <N> tasks · `docs/specs/<file>` committed

**Next:** run /triage
```

## Rules

- Create nothing on GitHub until I reply `create`.
- Re-read the spec file at create time — my edits are the source of truth.
- One combined file per spec. Vertical slices only; never a horizontal split.
- Never create a task that depends on another task finishing — recut instead.
- Labels only: `spec`, `task`, `ready`. No assignees, milestones, or projects.
- If `gh` is not authenticated: stop and print "Run: gh auth login".
