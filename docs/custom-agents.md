# Custom subagents: capability reference

What a custom subagent can do, which fields survive in a plugin, and how `macos-doctor` uses
them. Companion to [`agents/macos-doctor.md`](../agents/macos-doctor.md).

A subagent is a Markdown file: YAML frontmatter for configuration, body for the system prompt.
It runs in its own context window, so its intermediate work — command output, file reads, search
results — never reaches your main conversation. Only its final report does.

## Frontmatter fields

Only `name` and `description` are required.

| Field | Values | Notes |
|---|---|---|
| `name` | lowercase + hyphens | Identity. Cannot contain `:` (reserved for plugin scoping). The filename does not have to match. |
| `description` | prose | How Claude decides to delegate. See [writing it well](#the-description-field-is-the-routing-logic). |
| `tools` | tool names, comma-separated | Allowlist. Omit to inherit everything available to subagents. |
| `disallowedTools` | tool names | Denylist. Applied *before* `tools`. Accepts `mcp__<server>` patterns; `mcp__*` denies all MCP tools. |
| `model` | `sonnet`, `opus`, `haiku`, `fable`, a full ID, or `inherit` | Defaults to `inherit`. |
| `effort` | `low`, `medium`, `high`, `xhigh`, `max` | Overrides session effort. Available levels depend on the model. |
| `maxTurns` | integer | Hard stop on agentic turns. |
| `skills` | skill names | Preloads **full skill content** at startup, not just the description. |
| `memory` | `user`, `project`, `local` | Persistent directory across sessions. [Details](#memory-makes-an-agent-compound). |
| `background` | `true` | Always run as a background task. Unset lets Claude choose — and it defaults to background. |
| `isolation` | `worktree` | Runs in a temporary git worktree. Only valid value. Auto-cleaned if nothing changed. |
| `color` | `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan` | Display only. **Not supported in plugin agents.** |
| `initialPrompt` | prose | Auto-submitted as the first turn when the agent runs as the main session. |
| `hooks` | hook config | **Refused in plugin agents.** |
| `mcpServers` | server names or inline defs | **Refused in plugin agents.** |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan` | **Refused in plugin agents.** |

### The three fields plugins cannot use

`hooks`, `mcpServers`, and `permissionMode` are ignored when an agent loads from a plugin — a
plugin you install should not be able to grant itself permission modes or run hook scripts. To
use them, copy the agent file into `.claude/agents/` or `~/.claude/agents/`. See
[hardening](#hardening-recipe-real-read-only-enforcement) for a worked example.

`color` is documented for subagents generally but is absent from the plugin-agent allowlist, so
`macos-doctor` omits it rather than setting a field that gets dropped.

## Where agents live, and who wins

Same `name` in two places? Highest priority wins.

| Location | Scope | Priority |
|---|---|---|
| Managed settings | Organization-wide | 1 (highest) |
| `--agents` CLI flag | Current session only, not written to disk | 2 |
| `.claude/agents/` | Current project | 3 |
| `~/.claude/agents/` | All your projects | 4 |
| Plugin `agents/` | Wherever the plugin is enabled | 5 (lowest) |

Plugin agents sit at the bottom, so a user can always override one by dropping a file with the
same `name` into their own `.claude/agents/`.

All locations are scanned recursively. For project and user scopes a subfolder is organizational
only. For **plugin** agents the subfolder becomes part of the identifier: `agents/review/security.md`
in plugin `my-plugin` registers as `my-plugin:review:security`.

## Tool filtering: the non-obvious part

Your `tools` list is not the final word. Two filters run after it.

**Always removed from every subagent**, even if you list them: `AskUserQuestion`,
`EnterPlanMode`, `ExitPlanMode` (unless `permissionMode: plan`), `EndConversation`,
`ScheduleWakeup`, `TaskOutput`, `WaitForMcpServers`, `Workflow`, and `Agent` at the nesting
depth limit.

**Background subagents keep a reduced built-in set.** Since subagents run in the background by
default, this is the common path, not the edge case. A background subagent keeps every MCP tool
but only these built-ins:

```
Read  Grep  Glob  Bash  PowerShell  Edit  Write  NotebookEdit  WebFetch  WebSearch
TodoWrite  Skill  ToolSearch  EnterWorktree  ExitWorktree  Monitor  TaskStop
SendMessage  Artifact
```

Everything else is dropped silently. **The same definition can resolve to a different tool set
in the foreground than in the background.** If an agent depends on a built-in outside that list,
it will work when Claude happens to run it in the foreground and quietly lose the tool when it
does not.

`macos-doctor` uses `Bash, Read, Grep, Glob` — all four are in the reduced set, so it behaves
identically either way. That is a deliberate design constraint, not a coincidence.

If nothing in `tools` resolves to a real tool, the agent refuses to launch and names the bad
entries.

## The `description` field is the routing logic

Claude reads only the `description` when deciding whether to delegate. It is not documentation —
it is the dispatch condition.

Name the **symptoms** that should trigger it, not the agent's job title. `macos-doctor` lists
"a command resolves to the wrong binary", "a build fails with architecture errors", "a tool is
not found right after installing it" — phrasings close to what someone actually types when they
hit the problem. A description reading "expert macOS helper" gives the router nothing to match.

State the constraints too. `macos-doctor` says "read-only" in its description so Claude does not
route a "fix my PATH" request to an agent that will refuse to fix anything.

Add "use proactively" to encourage delegation without being asked.

## Memory makes an agent compound

`memory` gives the agent a directory that survives across conversations.

| Scope | Location | Use when |
|---|---|---|
| `user` | `~/.claude/agent-memory/<name>/` | Knowledge spans every project — machine facts, personal conventions |
| `project` | `.claude/agent-memory/<name>/` | Project-specific and shareable via version control |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific but not committed |

For a **plugin** agent, `<name>` is the plugin-scoped identifier with non-alphanumeric
characters replaced by `-`. `macos-doctor` shipped by `cc-plugin` writes to
`~/.claude/agent-memory/cc-plugin-macos-doctor/`, not `.../macos-doctor/`. Worth knowing before
you go looking for the directory, and it means the same agent file writes to different locations
depending on whether it loads from a plugin or from `.claude/agents/`.

The agent's system prompt gets memory instructions plus the first 200 lines / 25KB of
`MEMORY.md`.

`macos-doctor` uses `user` because its subject is *this Mac*, not any repository. The payoff is
specific: it records the machine baseline so later runs skip re-deriving it, and it records
setups you confirm are intentional so it stops re-flagging them. A diagnostic agent that reports
the same known-good configuration as a defect on every run gets ignored, which is the real
failure mode for this category of tool.

**Two caveats.** Enabling `memory` automatically turns on `Read`, `Write`, and `Edit` so the
agent can manage its own files — this overrides your `tools` list, so an agent with `memory` is
never write-free at the tool level. And memory rides on auto memory: if that is off
(`autoMemoryEnabled: false` or `CLAUDE_CODE_DISABLE_AUTO_MEMORY`), the field does nothing.

## Invoking an agent

| Method | Behavior |
|---|---|
| Automatic | Claude matches the task against `description` |
| `@agent-cc-plugin:macos-doctor` | Guarantees this agent runs for one task |
| `claude --agent macos-doctor` | The **whole session** adopts its system prompt, tools, and model |
| `"agent": "macos-doctor"` in settings | Same, as the project default |

With `--agent`, the agent's system prompt replaces the Claude Code system prompt entirely.
`CLAUDE.md` still loads.

Plugin agents appear in the `@` typeahead under the scoped name. Pass just the bare name to
`--agent` unless two plugins collide.

## What the agent sees at startup

A fresh context window — not your conversation history, not files already read. It gets its own
system prompt plus environment details, the delegation prompt Claude writes, your `CLAUDE.md`
hierarchy, a git status snapshot, and any preloaded `skills`.

It does **not** get your output style, the main conversation's auto memory, or your context
window size — the window is sized by the agent's own model.

Consequence: a rule that matters to the agent has to be in its system prompt, its preloaded
skills, or the delegation prompt. Assuming it inherits conversational context is the most common
way a custom agent underperforms.

## Design walkthrough: macos-doctor

| Field | Value | Why |
|---|---|---|
| `tools` | `Bash, Read, Grep, Glob` | All in the background-safe set, so foreground and background behave identically. Bash for probes, Read/Grep for dotfiles. |
| `model` | `inherit` | Diagnosis quality tracks the session's model; leaves cost to the caller. |
| `effort` | `high` | The work is correlating weak signals — PATH order against startup-file order against shim locations. Under-reasoning produces confident wrong causes. |
| `maxTurns` | `30` | Enough for a multi-group sweep; bounds a probe loop that finds nothing. |
| `memory` | `user` | Subject is the machine, not the repo. |
| `description` | symptom-led | Routes on what the user types when broken, and declares read-only so fix requests go elsewhere. |
| `color` | omitted | Not on the plugin-agent allowlist. |

The read-only property is worth being precise about. It is **not** enforced by the tool list —
`Bash` can mutate, and `memory` adds `Write`/`Edit` regardless. It is enforced by the system
prompt's explicit contract plus your normal permission prompts on mutating commands. For hard
enforcement, see below.

## Hardening recipe: real read-only enforcement

Since plugin agents cannot use `hooks`, copy the agent out of the plugin to add a `PreToolUse`
guard that blocks mutating Bash commands before they run:

```bash
cp agents/macos-doctor.md ~/.claude/agents/macos-doctor.md
```

Add to its frontmatter:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "~/.claude/scripts/deny-mutating-bash.sh"
```

`~/.claude/scripts/deny-mutating-bash.sh` — exit code 2 blocks the call and returns stderr to
the agent:

```bash
#!/usr/bin/env bash
set -euo pipefail

CMD=$(jq -r '.tool_input.command // empty')

if printf '%s' "$CMD" | grep -qE '(^|[;&|[:space:]])(sudo|rm|mv|chmod|chown|ln)([[:space:]]|$)|brew[[:space:]]+(install|uninstall|upgrade|link|unlink|cleanup|reinstall)|defaults[[:space:]]+write|launchctl[[:space:]]+(load|unload|bootout)|xcode-select[[:space:]]+--switch|[[:space:]]>[^&]'; then
  echo "Blocked: macos-doctor is read-only. Report the command for the user to run instead." >&2
  exit 2
fi

exit 0
```

```bash
chmod +x ~/.claude/scripts/deny-mutating-bash.sh
```

Requires `jq`. The pattern is a denylist, so treat it as defense in depth over the system
prompt's contract rather than a security boundary — a sufficiently creative command can evade
any regex. Project-level agents also need the folder's workspace-trust dialog accepted before
frontmatter hooks run.

## Local development

```bash
claude --plugin-dir .                # load without installing
claude plugin validate . --strict    # validate before publishing
```

Claude Code watches `.claude/agents/` and `~/.claude/agents/` and picks up edits within seconds.
Two cases still need a restart: creating the *first* agent file in a directory that did not exist
when the session started, and sessions launched with `--disable-slash-commands`.

To disable an agent without deleting it:

```json
{ "permissions": { "deny": ["Agent(macos-doctor)"] } }
```

## Source

- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [Hooks](https://code.claude.com/docs/en/hooks)
