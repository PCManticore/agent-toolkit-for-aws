#!/usr/bin/env bash
# Run one SDLC phase prompt through headless Claude Code with the local aws-sdlc + aws-core plugins.
#
# Usage: tools/dev/run-phase.sh <work-dir> <label> "<prompt>"
# Writes <work-dir>/.e2e-logs/<label>.jsonl and prints a summary.
# The agent may run shell commands and AWS MCP tools in <work-dir>; destructive AWS CLI verbs
# and recursive deletes are denied. Point it at a non-production account.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="$1"; LABEL="$2"; PROMPT="$3"
mkdir -p "$WORK_DIR/.e2e-logs"
LOG="$WORK_DIR/.e2e-logs/$LABEL.jsonl"

(cd "$WORK_DIR" && timeout "${PHASE_TIMEOUT:-1500}" claude -p "$PROMPT" \
  --plugin-dir "$REPO_ROOT/plugins/aws-sdlc" --plugin-dir "$REPO_ROOT/plugins/aws-core" \
  --output-format stream-json --verbose --max-turns "${MAX_TURNS:-80}" \
  --allowedTools "Read" "Write" "Edit" "Glob" "Grep" "Skill" "Bash" "WebFetch" \
                 "mcp__plugin_aws-sdlc_aws-mcp__*" "mcp__plugin_aws-core_aws-mcp__*" "mcp__aws-mcp__*" \
  --disallowedTools "Bash(rm -rf:*)" "Bash(aws * delete*)" "Bash(aws * terminate*)" \
                    "Bash(cdk destroy:*)" "Bash(npx cdk destroy:*)" "Bash(git push:*)" \
  >"$LOG" 2>&1)
echo "exit=$? log=$LOG"
python3 "$REPO_ROOT/tools/dev/summarize_run.py" "$LOG"
