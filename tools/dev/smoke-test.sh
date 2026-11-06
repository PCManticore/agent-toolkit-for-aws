#!/usr/bin/env bash
# Smoke-test phase routing: send one prompt per SDLC phase to Claude Code (headless) with the
# local aws-sdlc + aws-core plugins loaded, and check which skill the agent invoked.
#
# Usage: tools/dev/smoke-test.sh [demo-dir]   (default: /tmp/aws-sdlc-demo)
# Needs: claude CLI on PATH. Makes no AWS calls of its own; prompts ask for plans only.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEMO_DIR="${1:-/tmp/aws-sdlc-demo}"
LOG_DIR="$DEMO_DIR/smoke-logs"
mkdir -p "$LOG_DIR"

# expected-skill|prompt
CASES=(
  "aws-intent|I want to build a small service that receives webhook events from a partner and lets our team search them. Help me figure out what to build on AWS. Do not write code yet."
  "aws-readiness|We are about to launch our checkout API to production next week. Are we operationally ready? Tell me what you would check."
  "aws-maintain|Our image-processing service on AWS started throwing 5xx errors an hour ago. Help us triage it."
)

pass=0; fail=0
for case in "${CASES[@]}"; do
  expected="${case%%|*}"; prompt="${case#*|}"
  log="$LOG_DIR/$expected.jsonl"
  (cd "$DEMO_DIR" && claude -p "$prompt" \
      --plugin-dir "$REPO_ROOT/plugins/aws-sdlc" --plugin-dir "$REPO_ROOT/plugins/aws-core" \
      --output-format stream-json --verbose --max-turns 8 \
      --disallowedTools "Bash" "Write" "Edit" >"$log" 2>&1)
  invoked=$(python3 - "$log" <<'EOF'
import json, sys
names = []
for line in open(sys.argv[1]):
    try: ev = json.loads(line)
    except ValueError: continue
    msg = ev.get("message")
    if not isinstance(msg, dict): continue
    for block in msg.get("content") or []:
        if isinstance(block, dict) and block.get("type") == "tool_use" and block.get("name") == "Skill":
            names.append(str(block.get("input", {}).get("skill") or block.get("input", {}).get("command")))
print(" ".join(names))
EOF
)
  if [[ " $invoked " == *"$expected"* ]]; then
    echo "PASS  $expected  (skills invoked: $invoked)"; pass=$((pass+1))
  else
    echo "FAIL  $expected  (skills invoked: ${invoked:-none})  log: $log"; fail=$((fail+1))
  fi
done
echo "--- $pass passed, $fail failed"
[[ $fail -eq 0 ]]
