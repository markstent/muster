# Contributing to Muster

Muster is a small, opinionated set of Agent Skills. Contributions that
keep it focused and consistent are welcome.

## Project layout

```
.claude-plugin/
  plugin.json        plugin manifest
  marketplace.json   makes this repo its own single-plugin marketplace
skills/              the seven skills (one <name>/SKILL.md per command)
setup-labels.sh      creates the GitHub labels Muster uses
install.sh           non-plugin install (clone + symlink skills)
```

Each command is a single `skills/<name>/SKILL.md` file with YAML frontmatter
(`name`, `disable-model-invocation: true`, `description`) followed by the
instructions the agent runs. `name` must match the directory name. The bodies
are harness-agnostic: they speak in actions ("spawn a sub-agent", "read a
file"), not one tool's API, so the same file works in Claude Code, Cursor,
Codex, Gemini CLI, and any other reader of the Agent Skills spec.

## Editing a command

- Keep the existing voice: second person, terse, imperative. State rules as
  hard limits at the end.
- Preserve the guardrails. The safety properties are the point of Muster:
  `/triage` is read-only on code, `/build` never pushes to main and never
  auto-merges, risk gates autonomy, and every gate waits for the user.
- Use the shared vocabulary: the label system in the README, the `risk:*`
  scheme, and the state machine in `skills/triage/SKILL.md` must stay consistent across
  every command.

## Output discipline

Muster optimises for token economy and a clean terminal, and it must read
plainly for users of any technical level. Every command shares one output style
so the suite reads as one tool, not seven:

- **Plain first, precise underneath.** Lead every gate and verdict with one
  plain sentence saying what just happened, and end it with a clear
  call-to-action: a bold `**Your move:**` line for interactive gates, or a
  `**Next:**` line otherwise. Someone non-technical should be able to act on the
  lead; the tables and detail below are for those who want them.
- **Translate on the way out.** Keep Muster's internal vocabulary in the
  instructions, never in what you print. Do not surface "two-track", "vertical
  slice / tracer bullet", "burnout cap", "state machine", "inner review", or
  "worktree" to the user. Gloss every label and risk where it is shown (e.g.
  "Agent-ready - ready for me to build on my own"). Keep the muster theme and
  the Manager/builder roles, but introduce them in plain words.
- **Rendered markdown, never code fences for layout.** Lead with a
  `## <command> - <verdict or headline>` line, then the detail. Code fences are
  only for literal copyable content: shell commands, diffs, branch names, paths.
- **Tabular data goes in markdown tables** (2-4 columns). Put wider per-item
  detail in short `###` blocks or bold lines, not extra columns, so nothing
  wraps on a narrow terminal.
- **One status-glyph set, used everywhere:**
  - ✅ pass / ready / approved / safe to merge / done
  - ❌ fail / blocker / blocked / do not merge
  - ⚠️ warning / judgement call / medium risk / needs attention
  - ⏭️ deferred / skipped / on hold
- **Risk stays textual** (`low` / `medium` / `high`) in its own column or inline.
- Never dump sub-agent reports verbatim; synthesise to terse bullets.
- Expand and edit out of band - write artifacts (like the spec file) to disk for
  the user to edit in their editor rather than reprinting them across turns.
- End each command with a `**Next:**` line naming the command that follows.

## Testing a change locally

Install your working copy as a plugin and exercise the command end to end:

```bash
/plugin marketplace add /absolute/path/to/your/muster/checkout
/plugin install muster@muster
```

Or symlink it for the bare-command path:

```bash
bash ./install.sh   # uses this checkout if MUSTER_HOME points at it
```

Validate the plugin manifest before opening a PR:

```bash
claude plugin validate .
```

When exercising `/build`, note it re-runs the target repo's `Test command:`
(from CONTEXT.md) against each branch and gates on its own run, not the Worker's
pasted output - so the target repo must declare a runnable test command.
Recommended belt-and-suspenders for repos muster builds in: also gate PRs in CI,
so tests are enforced at merge independent of the agent.

## Pull requests

- One command or one concern per PR.
- Update the README (command table, flow, labels) if behaviour changes.
- Bump `version` in `.claude-plugin/plugin.json` for any user-visible change.

## License

By contributing you agree your contributions are licensed under the MIT
License (see [LICENSE](LICENSE)).
