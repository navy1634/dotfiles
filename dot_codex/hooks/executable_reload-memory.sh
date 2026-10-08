#!/bin/sh
set -u

recovery_context=$(cat <<'EOF'
This session has just been compacted. Before continuing:
1. Re-read each applicable AGENTS.md.
2. Inspect git status and git diff in the repository.
3. Reconstruct the task goal, completed work, and remaining work.
4. Do not treat the compacted conversation as the sole source of truth.
5. Prefer repository files, applicable AGENTS.md, and MEMORY.md in the Codex home.
EOF
)

fallback_output='{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This session has just been compacted. Re-read applicable AGENTS.md files; inspect git status and git diff; reconstruct the current task goal, completed work, and remaining work; do not treat the compacted conversation as the sole source of truth; prefer repository files, AGENTS.md, and MEMORY.md in the Codex home."}}'

if [ -n "${CODEX_HOME:-}" ]; then
  memory_file="${CODEX_HOME}/MEMORY.md"
elif [ -n "${HOME:-}" ]; then
  memory_file="${HOME}/.codex/MEMORY.md"
else
  memory_file=
fi

if [ -n "$memory_file" ] && [ -r "$memory_file" ] && command -v jq >/dev/null 2>&1; then
  if json_output=$(jq -n --arg recovery "$recovery_context" --rawfile memory "$memory_file" '
    {
      hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: (
          $recovery
          + (if $memory == "" then "" else "\n\nPersistent memory from the Codex home MEMORY.md:\n" + $memory end)
        )
      }
    }
  ' 2>/dev/null); then
    printf '%s\n' "$json_output"
    exit 0
  fi
fi

printf '%s\n' "$fallback_output"
exit 0
