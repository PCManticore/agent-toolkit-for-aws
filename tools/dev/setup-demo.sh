#!/usr/bin/env bash
# Set up an isolated demo workspace for the aws-sdlc plugin.
#
# Usage: tools/dev/setup-demo.sh [demo-dir]   (default: <repo>/../aws-sdlc-demo-run)
#
# The workspace sees ONLY the seven aws-sdlc skills, in both agents:
#   - Claude Code runs with its own CLAUDE_CONFIG_DIR, so your ~/.claude plugins, skills and MCP
#     servers are not loaded. The aws-sdlc plugin is loaded with --plugin-dir from this checkout.
#   - Kiro CLI runs with its own KIRO_HOME and chat.disableInheritingDefaultResources, so
#     ~/.kiro/skills and ~/.kiro/steering are not loaded.
# Domain skills (aws-serverless, aws-lambda-web-functions, ...) come from the AWS MCP Server on demand.
#
# Creates in <demo-dir>:
#   ./claude-demo   ./kiro-demo   launchers (tools auto-approved, destructive commands denied)
#   ./teardown.sh   deletes every SdlcDemo* stack and sdlc-demo* web function in us-west-2
#   DEMO.md         the run sheet with every prompt
#   welcome.sh      the intro screen the launchers show on an interactive start
#   .claude/settings.json   auto-approve rules plus the AWS SDLC status line (phase + what to say next)
#   .claude/commands/demo-*.md, .kiro/prompts/demo-*.md   the same prompts as slash commands
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEMO_DIR="${1:-$(dirname "$REPO_ROOT")/aws-sdlc-demo-run}"
PLUGIN="$REPO_ROOT/plugins/aws-sdlc"

# An AWS CLI v2 new enough to have `aws lambda-web` (Lambda Web Functions).
AWS_BIN=""
for candidate in /opt/homebrew/bin/aws /usr/local/bin/aws $(command -v -a aws 2>/dev/null || true); do
  if [[ -x "$candidate" ]] && "$candidate" lambda-web help >/dev/null 2>&1; then AWS_BIN="$candidate"; break; fi
done
if [[ -z "$AWS_BIN" ]]; then
  echo "No AWS CLI with 'aws lambda-web' found. Install or update AWS CLI v2 first." >&2; exit 1
fi
AWS_DIR="$(dirname "$AWS_BIN")"

mkdir -p "$DEMO_DIR"
cp -R "$REPO_ROOT/demo/workspace/." "$DEMO_DIR/"
cp "$DEMO_DIR/AGENTS.md" "$DEMO_DIR/CLAUDE.md"
cp "$REPO_ROOT/demo/README.md" "$DEMO_DIR/DEMO.md"
cp "$REPO_ROOT/demo/welcome.sh" "$DEMO_DIR/welcome.sh"
mkdir -p "$DEMO_DIR/.claude/commands" "$DEMO_DIR/.kiro/prompts" "$DEMO_DIR/.claude-home" "$DEMO_DIR/.kiro-home/agents" "$DEMO_DIR/.kiro-home/settings"
for prompt in "$REPO_ROOT"/demo/prompts/*.md; do
  name="demo-$(basename "$prompt")"
  cp "$prompt" "$DEMO_DIR/.claude/commands/$name"
  # Kiro file prompts take the body only.
  awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2 || fm==0' "$prompt" > "$DEMO_DIR/.kiro/prompts/$name"
done
[[ -d "$DEMO_DIR/.git" ]] || git -C "$DEMO_DIR" init -q

python3 - "$REPO_ROOT" "$DEMO_DIR" <<'EOF'
import json, pathlib, sys

repo, demo = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]).resolve()
plugin = repo / "plugins" / "aws-sdlc"

# Claude Code: private config dir. Carry over only the model-provider env (for example Bedrock).
user_settings = pathlib.Path.home() / ".claude" / "settings.json"
env = {}
if user_settings.exists():
    env = {k: v for k, v in json.loads(user_settings.read_text()).get("env", {}).items()
           if k.startswith(("CLAUDE_CODE_USE_", "AWS_", "ANTHROPIC_")) and "KEY" not in k and "TOKEN" not in k}
home = demo / ".claude-home"
(home / "settings.json").write_text(json.dumps({"env": env}, indent=2) + "\n")
state = home / ".claude.json"
data = json.loads(state.read_text()) if state.exists() else {}
data.update({"hasCompletedOnboarding": True, "theme": data.get("theme", "dark")})
data.setdefault("projects", {})[str(demo)] = {"hasTrustDialogAccepted": True, "allowedTools": []}
state.write_text(json.dumps(data, indent=2) + "\n")

# Claude Code status line: lifecycle progress and the next prompt, always on screen.
ws = demo / ".claude" / "settings.json"
cfg = json.loads(ws.read_text())
cfg["statusLine"] = {"type": "command", "padding": 0,
                     "command": f"python3 {plugin / 'com.anthropic.claude-code' / 'statusline.py'}"}
ws.write_text(json.dumps(cfg, indent=2) + "\n")

# Kiro CLI: private KIRO_HOME, an agent that declares only the SDLC skills.
skills = sorted(str(p) for p in (plugin / "skills").glob("*/SKILL.md"))
hook = plugin / "com.anthropic.claude-code" / "hooks" / "sdlc-context.py"
agent = {
    "name": "aws-sdlc-demo",
    "description": "Agent Toolkit for AWS reorganized around SDLC phases (local checkout).",
    "prompt": "You help users build and run workloads on AWS by following the AWS SDLC lifecycle skills.",
    "mcpServers": json.loads((plugin / ".mcp.json").read_text())["mcpServers"],
    "tools": ["*"],
    "allowedTools": ["*"],
    "resources": ["file://AGENTS.md"] + [f"skill://{s}" for s in skills],
    "hooks": {"userPromptSubmit": [{"command": f"python3 {hook} --plain"}]},
}
(demo / ".kiro-home" / "agents" / "aws-sdlc-demo.json").write_text(json.dumps(agent, indent=2) + "\n")
(demo / ".kiro-home" / "settings" / "cli.json").write_text(
    json.dumps({"chat.disableInheritingDefaultResources": True, "chat.defaultAgent": "aws-sdlc-demo"}, indent=2) + "\n")
print(f"Configured {len(skills)} skills for Claude Code and Kiro CLI")
EOF

cat > "$DEMO_DIR/claude-demo" <<EOF
#!/usr/bin/env bash
# Claude Code with only the aws-sdlc plugin, tools auto-approved per .claude/settings.json.
cd "\$(dirname "\$0")"
export PATH="$AWS_DIR:\$PATH" CLAUDE_CONFIG_DIR="$DEMO_DIR/.claude-home" AWS_REGION=us-west-2
# Interactive start (no arguments): show how to use the plugin first.
if [[ \$# -eq 0 && -t 1 ]]; then
  clear; bash welcome.sh; read -r -p "  Press Enter to start Claude Code... " _
fi
exec claude --plugin-dir "$PLUGIN" "\$@"
EOF
cat > "$DEMO_DIR/kiro-demo" <<EOF
#!/usr/bin/env bash
# Kiro CLI with only the aws-sdlc skills, all tools trusted.
cd "\$(dirname "\$0")"
export PATH="$AWS_DIR:\$PATH" KIRO_HOME="$DEMO_DIR/.kiro-home" AWS_REGION=us-west-2
# Interactive start (no arguments): show how to use the plugin first.
if [[ \$# -eq 0 && -t 1 ]]; then
  clear; bash welcome.sh; read -r -p "  Press Enter to start Kiro CLI... " _
fi
exec kiro-cli chat --agent aws-sdlc-demo --trust-all-tools "\$@"
EOF
cat > "$DEMO_DIR/teardown.sh" <<EOF
#!/usr/bin/env bash
# Delete everything the demo created in us-west-2: SdlcDemo* stacks and sdlc-demo* web functions.
set -uo pipefail
export PATH="$AWS_DIR:\$PATH" AWS_REGION=us-west-2
for stack in \$(aws cloudformation list-stacks --query "StackSummaries[?starts_with(StackName,'SdlcDemo') && StackStatus!='DELETE_COMPLETE'].StackName" --output text); do
  echo "Deleting stack \$stack"; aws cloudformation delete-stack --stack-name "\$stack"
done
for fn in \$(aws lambda-web list-web-functions --query "functions[?starts_with(functionName,'sdlc-demo')].functionName" --output text 2>/dev/null); do
  echo "Deleting web function \$fn"; aws lambda-web delete-web-function --function-name "\$fn"
done
for stack in \$(aws cloudformation list-stacks --query "StackSummaries[?starts_with(StackName,'SdlcDemo') && StackStatus=='DELETE_IN_PROGRESS'].StackName" --output text); do
  aws cloudformation wait stack-delete-complete --stack-name "\$stack" && echo "Deleted \$stack"
done
echo "Resources still tagged project=sdlc-demo:"
aws resourcegroupstaggingapi get-resources --tag-filters Key=project,Values=sdlc-demo --query 'ResourceTagMappingList[].ResourceARN' --output text
EOF
chmod +x "$DEMO_DIR/claude-demo" "$DEMO_DIR/kiro-demo" "$DEMO_DIR/teardown.sh"

cat <<EOF

Demo workspace ready: $DEMO_DIR  (AWS CLI: $AWS_BIN)

  cd $DEMO_DIR
  ./claude-demo        # then type /demo-1-intent, /demo-2-build, ...
  ./kiro-demo          # same: /demo-1-intent, /demo-2-build, ... (or paste from DEMO.md)
  ./teardown.sh        # at the end

Restart the lifecycle by deleting .aws-sdlc/ and the generated app files.
EOF
