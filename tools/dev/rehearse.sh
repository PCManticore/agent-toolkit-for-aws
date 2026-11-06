#!/usr/bin/env bash
# Rehearse one demo step headlessly through the demo launcher (same isolation and permissions as live).
#
# Usage: tools/dev/rehearse.sh <demo-dir> <step> [extra prompt text]
#   step: 0-start | 1-intent | 2-build | 3-verify | 4-orr | 5-deploy | 5b-fix-and-deploy | 6-maintain
# Runs in the background; logs to <demo-dir>/.rehearsal/<step>.jsonl. Summarize with
#   python3 tools/dev/summarize_run.py <demo-dir>/.rehearsal/<step>.jsonl
set -euo pipefail
DEMO_DIR="$1"; STEP="$2"; EXTRA="${3:-}"
mkdir -p "$DEMO_DIR/.rehearsal"
LOG="$DEMO_DIR/.rehearsal/$STEP.jsonl"
PROMPT="/demo-$STEP${EXTRA:+ $EXTRA}"
nohup "$DEMO_DIR/claude-demo" -p "$PROMPT" --output-format stream-json --verbose \
  --max-turns "${MAX_TURNS:-150}" >"$LOG" 2>&1 &
echo "started pid $! -> $LOG"
