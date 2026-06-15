# Contributing to Muster

Muster is a small, opinionated set of Claude Code commands. Contributions that
keep it focused and consistent are welcome.

## Project layout

```
.claude-plugin/
  plugin.json        plugin manifest
  marketplace.json   makes this repo its own single-plugin marketplace
commands/            the seven slash commands (one .md per command)
setup-labels.sh      creates the GitHub labels Muster uses
install.sh           non-plugin install (clone + symlink commands)
```

Each command is a single Markdown file in `commands/` with YAML frontmatter
(`name`, `description`) followed by the instructions Claude runs.

## Editing a command

- Keep the existing voice: second person, terse, imperative. State rules as
  hard limits at the end.
- Preserve the guardrails. The safety properties are the point of Muster:
  `/triage` is read-only on code, `/build` never pushes to main and never
  auto-merges, risk gates autonomy, and every gate waits for the user.
- Use the shared vocabulary: the label system in the README, the `risk:*`
  scheme, and the state machine in `triage.md` must stay consistent across
  every command.

## Output discipline

muster optimises for token economy. Keep command output and generated artifacts
lean:

- Compact, rendered markdown — verdict/headline first, details below. No ```
  ASCII boxes for summaries.
- Text status markers only: `PASS`/`FAIL`, and `[x]` / `[!]` / `[ok]`. No emojis.
- Expand and edit out of band — write artifacts (like the spec file) to disk for
  the user to edit in their editor rather than reprinting them across turns.
- Never dump sub-agent reports verbatim; synthesise to terse bullets.
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

## Pull requests

- One command or one concern per PR.
- Update the README (command table, flow, labels) if behaviour changes.
- Bump `version` in `.claude-plugin/plugin.json` for any user-visible change.

## License

By contributing you agree your contributions are licensed under the MIT
License (see [LICENSE](LICENSE)).
