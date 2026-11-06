#!/usr/bin/env bash
# Set up an isolated demo workspace that loads the aws-sdlc and aws-core plugins
# straight from this checkout, without installing anything from a marketplace.
#
# Usage: tools/dev/setup-demo.sh [demo-dir]   (default: /tmp/aws-sdlc-demo)
#
# Creates:
#   <demo-dir>/.kiro/agents/aws-sdlc-demo.json  Kiro CLI agent that loads only this checkout's
#                                               skills (no ~/.kiro/skills mixing) + the AWS MCP Server
# and prints the Claude Code command that loads both plugins via --plugin-dir.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEMO_DIR="${1:-/tmp/aws-sdlc-demo}"

mkdir -p "$DEMO_DIR/.kiro/agents"

python3 - "$REPO_ROOT" "$DEMO_DIR" <<'EOF'
import json, pathlib, sys

repo, demo = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
skills = sorted(
    str(p) for plugin in ("aws-sdlc", "aws-core")
    for p in (repo / "plugins" / plugin / "skills").glob("*/SKILL.md")
)
mcp = json.loads((repo / "plugins" / "aws-sdlc" / ".mcp.json").read_text())["mcpServers"]
agent = {
    "name": "aws-sdlc-demo",
    "description": "Demo agent: Agent Toolkit for AWS reorganized around SDLC phases (local checkout).",
    "prompt": (
        "You help users build and run workloads on AWS. Start with the aws-sdlc skill to find the "
        "lifecycle phase, then follow the matching phase skill (aws-intent, aws-build, aws-verify, "
        "aws-orr, aws-deploy, aws-maintain), which routes to the domain skills for depth."
    ),
    "mcpServers": mcp,
    "tools": ["*"],
    "allowedTools": ["fs_read"],
    "resources": [f"skill://{s}" for s in skills],
}
out = demo / ".kiro" / "agents" / "aws-sdlc-demo.json"
out.write_text(json.dumps(agent, indent=2) + "\n")
print(f"Wrote {out} ({len(skills)} skills)")
EOF

cat <<EOF

Demo workspace ready: $DEMO_DIR

Kiro CLI:
  cd $DEMO_DIR && kiro-cli chat --agent aws-sdlc-demo

Claude Code:
  cd $DEMO_DIR && claude --plugin-dir $REPO_ROOT/plugins/aws-sdlc --plugin-dir $REPO_ROOT/plugins/aws-core

Claude Code via a local marketplace (persistent install, same result):
  /plugin marketplace add $REPO_ROOT
  /plugin install aws-sdlc@agent-toolkit-for-aws

Phase artifacts are written to $DEMO_DIR/.aws-sdlc/. Delete that folder to restart the lifecycle.
EOF
