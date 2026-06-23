---
name: context
disable-model-invocation: true
description: >
  (Muster) Write CONTEXT.md - the shared notes every other Muster command reads (your
  stack, your terms, your past decisions). Run once per repo, then refresh when
  something major changes or a past decision is reversed. Reads the repo; writes
  only CONTEXT.md.
---

# Context

Write and maintain `CONTEXT.md` at the repo root. It's the shared notes every
other Muster command reads - `/spec`, `/triage`, and `/build` - so the agents
speak your project's language and respect decisions you've already made. It's
working memory for the agents, not a doc for people: keep it dense and current,
not pretty.

You read the codebase. You write exactly one file: `CONTEXT.md`. Touch nothing
else.

## Step 1 - Detect first run vs refresh

- If `CONTEXT.md` does not exist, this is a first run: build it from scratch.
- If it exists, this is a refresh: read it first, preserve what is still true,
  and update only what has changed. Never silently drop an existing decision -
  if you believe one is now wrong, flag it to me before removing it.

## Step 2 - Read the repo

- `README.md` and any top-level docs.
- `git log --oneline -20` and the most recently changed source files.
- Package manifests (`package.json`, `pyproject.toml`, `go.mod`, etc.) for the
  stack and tooling.
- Any existing `docs/adr/`, `CONTRIBUTING.md`, `CLAUDE.md`/`AGENTS.md`, or
  style/standards files - these are existing decisions, not raw material to
  rewrite.

If something central is ambiguous (the core domain noun, the primary entry
point), ask me one targeted question rather than guessing.

## Step 3 - Write CONTEXT.md

Use this structure. Scale each section to the repo; omit a heading only if it
genuinely does not apply.

```
# CONTEXT

## Stack
[Languages, frameworks, key libraries, test runner, package manager.
 One line each.]
Test command: [single command that runs the full suite, e.g. `pytest -q`.
 /build re-runs exactly this to gate every task; /triage requires it before a
 task is agent-ready. Keep it one runnable line.]

## Domain glossary
[The nouns and verbs of this project, defined. The vocabulary every spec,
 task, and review must use. Two columns: term - meaning.]

## Architecture
[The shape of the system in a few sentences. Entry points, major modules,
 how data flows. Name the directories that matter.]

## Conventions
[How code is written here: naming, error handling, test style, anything a
 new contributor would get wrong. Point to the enforcing config where one
 exists rather than restating it.]

## Decisions (ADRs)
[Dated, one-line architectural decisions and their rationale. Newest first.
 Format: YYYY-MM-DD - decision - why. These are binding on /triage and /build.]

## Out of scope
[Things deliberately not built or not done, and why. Mirrors anything in
 .out-of-scope/.]
```

## Step 4 - Summarise

Print what you wrote or changed:

```
## Context - ✅ CONTEXT.md [created | updated]

Saved your project notes - the shared memory every Muster command now reads.

| | |
|---|---|
| Stack | [one line] |
| Glossary | [N terms] |
| Decisions | [N recorded] |
| Changed | [what this refresh added or revised, or "first run"] |

**Next:** run /spec to turn a resolved idea into issues.
```

## Rules

- Write only `CONTEXT.md`. Never modify code, branches, or other files.
- On a refresh, preserve existing decisions unless I approve removing one.
- Keep it terse. This is memory for agents, not a tutorial.
- Record decisions as they are made - a reversed decision is an update here,
  not a deletion of history.
