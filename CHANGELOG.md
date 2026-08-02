# Changelog

## 0.2.0

- Add `macos-doctor` agent: read-only diagnostics for macOS developer toolchain problems —
  PATH shadowing, Homebrew health, arm64/Rosetta mismatches, version-manager conflicts,
  Xcode/CLT state, and system-stub interpreters. Uses `memory: user` to build a per-machine
  baseline across sessions.
- Add `docs/custom-agents.md`: capability reference for custom subagents, including the
  frontmatter fields plugin agents cannot use and the background-subagent tool filtering rules.
- Remove the placeholder `agents/example-agent.md`; its annotated-template role moves to the
  capability reference.

## 0.1.0

- Initial scaffold: manifest, marketplace, example skill, agent, hook, MCP server, and
  output style.
