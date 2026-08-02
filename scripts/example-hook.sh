#!/usr/bin/env bash
# Example SessionStart hook for cc-plugin.
# Replace with real logic, or delete and remove the entry from hooks/hooks.json.
set -euo pipefail

echo "[cc-plugin] SessionStart hook fired (CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT:-unset})" >&2
