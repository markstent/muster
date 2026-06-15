---
name: review
description: >
  Review the changes since a fixed point along two axes — Standards (does the
  code follow this repo's documented conventions?) and Spec (does it implement
  what the issue asked for?). Runs both as parallel sub-agents and reports them
  side by side. Use before merging any PR, or to "review since X".
---

# Review

Two-axis review of the diff between `HEAD` and a fixed point you supply:

- Standards — does the code conform to this repo's documented conventions?
- Spec — does the code faithfully implement the originating issue or spec?

Both axes run as parallel sub-agents so they don't pollute each other's
context. Then this skill reports them side by side. A change can pass one and
fail the other — correct code implementing the wrong thing, or the right
behaviour built against the project's conventions — so the axes stay separate.

## Step 1 — Pin the fixed point

Whatever you said is the fixed point: a commit SHA, branch, tag, `main`,
`HEAD~5`, or a PR number. Pass it through; don't be opinionated. If you didn't
specify one, ask: "Review against what — a branch, a commit, or main?" Don't
proceed without it.

Capture the diff once:
```bash
git diff <fixed-point>...HEAD      # three-dot: compares against merge-base
git log <fixed-point>..HEAD --oneline
```
For a PR: `gh pr diff [NUMBER]` and `gh pr view [NUMBER]`.

## Step 2 — Identify the spec source

Look, in order:
1. Issue references in commit messages (`#123`, `Closes #45`) — fetch with `gh`.
2. A path I passed as an argument.
3. A spec/PRD file under `docs/`, `specs/`, or `.scratch/` matching the branch.
4. If nothing is found, ask where the spec is. If there isn't one, the Spec
   sub-agent skips and reports "no spec available".

## Step 3 — Identify the standards sources

Anything documenting how code should be written:
- `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CONTEXT.md`
- `docs/adr/` (architectural decisions are standards)
- `STYLE.md`, `STANDARDS.md`, `STYLEGUIDE.md`
- Machine-enforced config (eslint, prettier, tsconfig) — note it but don't
  re-check what tooling already enforces.

## Step 4 — Spawn both sub-agents in parallel

One message, two Task tool calls.

Standards sub-agent:
```
Read these standards docs: [list]. Then read this diff: [diff].
Report every place the diff violates a documented standard. Cite the standard
(file + rule). Distinguish hard violations from judgement calls. Skip anything
tooling enforces. Also flag security issues: unsanitised input, hardcoded
secrets, unvalidated endpoints, language-specific risks (SQL injection,
prototype pollution, path traversal). Under 400 words. End: STANDARDS PASS/FAIL.
```

Spec sub-agent:
```
Read the spec: [path or contents]. Then read this diff: [diff].
Report: (a) requirements asked for that are missing or partial; (b) behaviour
not asked for (scope creep); (c) requirements that look implemented but wrong.
Confirm tests exist for new behaviour and test through public interfaces, not
implementation details. Quote the spec line for each finding. Under 400 words.
End: SPEC PASS/FAIL.
```

If the spec is missing, skip the Spec sub-agent and note it.

## Step 5 — Aggregate

Present both reports under `## Standards` and `## Spec`, verbatim or lightly
cleaned. Do not merge or rerank — the axes are deliberately independent.

End with a one-line summary: findings per axis, and the single worst issue.

```
Verdict: [SAFE TO MERGE | DO NOT MERGE]
Standards: [PASS | FAIL] · Spec: [PASS | FAIL]
Worst issue: [one line, or "none"]
```

## Rules

- A security finding on the Standards axis is always DO NOT MERGE.
- A Spec FAIL (missing requirement or wrong implementation) is DO NOT MERGE.
- Don't suggest improvements beyond the two axes — the issue had defined
  acceptance criteria; anything more is scope creep.
- This is a read-only review. Never modify code or merge.
