# cc-plugin

A [Claude Code](https://code.claude.com/docs) plugin providing **`macos-doctor`**, a read-only
agent that diagnoses macOS developer toolchain problems. It doubles as a scaffold: it includes
a working example of every component type plugins support, so you can delete what you don't
need and build out the rest.

## macos-doctor

Finds out *why* your Mac's toolchain is misbehaving and gives you the exact fix — without
changing anything itself. It covers:

- **PATH shadowing** — which binary actually wins, and every one it beat
- **Architecture mismatches** — arm64 vs x86_64, Rosetta translation, a stray `/usr/local`
  Homebrew shadowing `/opt/homebrew`
- **Version managers** — pyenv/rbenv/nvm/fnm/mise/asdf shims installed but losing to Homebrew,
  or init lines in a startup file that doesn't load
- **Shell startup ordering** — why your editor and Finder-launched apps see a different PATH
  than Terminal
- **Homebrew health**, **Xcode/CLT state**, and macOS **system stubs** (`/usr/bin/ruby`,
  `/usr/bin/java`) beating real installs

Ask it directly, or let Claude route to it:

```
@agent-cc-plugin:macos-doctor why does python3 not use my pyenv version?
```

It reports findings ranked Critical/Warning/Note, each with the command it ran, that command's
real output, and a copy-pasteable fix. It never installs, uninstalls, `sudo`s, or edits your
dotfiles — see [read-only enforcement](docs/custom-agents.md#hardening-recipe-real-read-only-enforcement)
for how far that guarantee goes and how to harden it.

With `memory: user` it keeps a per-machine baseline in
`~/.claude/agent-memory/cc-plugin-macos-doctor/`, so repeat runs skip re-deriving your setup and
stop re-flagging quirks you've confirmed are intentional.

[**docs/custom-agents.md**](docs/custom-agents.md) documents the full custom-subagent capability
surface — every frontmatter field, the three that plugin agents refuse, and the background tool
filtering that trips people up.

## What's included

| Component      | Location                        | Notes |
|-----------------|----------------------------------|-------|
| Manifest        | `.claude-plugin/plugin.json`     | Plugin metadata |
| Marketplace     | `.claude-plugin/marketplace.json`| Lets this repo self-host for local install/testing |
| **Agent**       | `agents/macos-doctor.md`         | macOS toolchain diagnostics, `cc-plugin:macos-doctor` |
| Skill           | `skills/example-skill/SKILL.md`  | Invoked as `/cc-plugin:example-skill` or by the model |
| Hook            | `hooks/hooks.json`, `scripts/example-hook.sh` | `SessionStart` hook example |
| MCP server      | `.mcp.json`                      | Example stdio server (filesystem reference server) |
| Output style    | `output-styles/example-style.md` | Example output style |

Everything under `.claude-plugin/` other than `plugin.json` and `marketplace.json` does
**not** belong there — commands, skills, agents, hooks, and `.mcp.json` all live at the
plugin root, which is where this scaffold puts them.

## Developing locally

Load the plugin directly from disk for a single session, without installing it:

```bash
claude --plugin-dir .
```

Reload after editing skills/commands/agents without restarting:

```
/reload-plugins
```

Hook, MCP, and LSP config changes require a restart to take effect.

Validate the manifest and marketplace before publishing:

```bash
claude plugin validate . --strict
```

## Installing via the local marketplace

This repo defines its own marketplace (`.claude-plugin/marketplace.json`) pointing back
at itself, so you can exercise the real install path end-to-end:

```
/plugin marketplace add /path/to/cc-plugin
/plugin install cc-plugin@cc-plugin-marketplace
```

## Customizing

1. Update `.claude-plugin/plugin.json` — `name`, `description`, `author`, `repository`.
2. Replace or remove `skills/example-skill/` and `output-styles/example-style.md`. For a new
   agent, `docs/custom-agents.md` has the annotated field reference.
3. Point `.mcp.json` at a real MCP server, or delete it if the plugin doesn't need one.
4. Edit `hooks/hooks.json` and `scripts/example-hook.sh`, or delete both if you don't
   need hooks.
5. Update this README and `CHANGELOG.md`.

## Reference

- Custom subagents: https://code.claude.com/docs/en/sub-agents
- Plugins: https://code.claude.com/docs/en/plugins
- Plugins reference: https://code.claude.com/docs/en/plugins-reference
- Plugin marketplaces: https://code.claude.com/docs/en/plugin-marketplaces
- Hooks: https://code.claude.com/docs/en/hooks
