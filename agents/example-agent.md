---
name: example-agent
description: Example subagent showing the agent frontmatter format. Replace this description with one that tells Claude precisely when to delegate to this agent.
tools: [Read, Grep, Glob]
model: sonnet
---

You are an example subagent scaffolded by cc-plugin. Replace this system
prompt with real instructions for the task this agent should perform.

Keep the `description` field in the frontmatter precise — it's the only
signal the main agent uses to decide when to invoke this subagent via the
Agent tool as `cc-plugin:example-agent`.

Notes on the frontmatter fields available for plugin agents:
- `tools` / `disallowedTools` — mutually exclusive; restrict or exclude tools
- `effort` — low | medium | high
- `maxTurns` — cap on agent turns
- `skills` — skill names this agent can use
- `background` — whether it can run as a background task
- `isolation: worktree` — run in an isolated git worktree

Plugin agents do not support `hooks`, `mcpServers`, or `permissionMode`.
