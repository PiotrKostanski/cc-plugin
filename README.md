# cc-plugin

A scaffold for a [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin. It
includes a working example of every component type plugins support, so you can delete
what you don't need and build out the rest.

## What's included

| Component      | Location                        | Notes |
|-----------------|----------------------------------|-------|
| Manifest        | `.claude-plugin/plugin.json`     | Plugin metadata |
| Marketplace     | `.claude-plugin/marketplace.json`| Lets this repo self-host for local install/testing |
| Skill           | `skills/example-skill/SKILL.md`  | Invoked as `/cc-plugin:example-skill` or by the model |
| Agent           | `agents/example-agent.md`        | Subagent, invoked as `cc-plugin:example-agent` |
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
2. Replace or remove `skills/example-skill/`, `agents/example-agent.md`,
   `output-styles/example-style.md`.
3. Point `.mcp.json` at a real MCP server, or delete it if the plugin doesn't need one.
4. Edit `hooks/hooks.json` and `scripts/example-hook.sh`, or delete both if you don't
   need hooks.
5. Update this README and `CHANGELOG.md`.

## Reference

- Plugin docs: https://docs.claude.com/en/docs/claude-code/plugins
- Plugin marketplaces: https://docs.claude.com/en/docs/claude-code/plugin-marketplaces
- Hooks: https://docs.claude.com/en/docs/claude-code/hooks
