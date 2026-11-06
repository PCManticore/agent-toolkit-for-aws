#!/usr/bin/env python3
"""Summarize a Claude Code stream-json log: skills invoked, AWS MCP tool calls, shell commands, final result."""
import json
import sys


def main(path: str) -> None:
    skills, mcp, bash, errors = [], [], [], []
    result = ""
    for line in open(path):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "result":
            result = str(ev.get("result", ""))
        msg = ev.get("message")
        if not isinstance(msg, dict):
            continue
        for block in msg.get("content") or []:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use":
                name, inp = block.get("name", ""), block.get("input") or {}
                if name == "Skill":
                    skills.append(str(inp.get("skill")))
                elif "aws-mcp" in name:
                    detail = inp.get("code") or inp.get("search_phrase") or inp.get("url") or inp.get("skill_name") or ""
                    mcp.append(f"{name.split('__')[-1]}: {' '.join(str(detail).split())[:160]}")
                elif name == "Bash":
                    bash.append(" ".join(str(inp.get("command", "")).split())[:200])
            elif block.get("type") == "tool_result" and block.get("is_error"):
                errors.append(" ".join(str(block.get("content")).split())[:240])
    print("SKILLS:", " ".join(skills) or "none")
    print(f"AWS MCP CALLS ({len(mcp)}):")
    for m in mcp:
        print("  ", m)
    print(f"BASH ({len(bash)}):")
    for b in bash:
        print("  ", b)
    print(f"TOOL ERRORS ({len(errors)}):")
    for e in errors[:15]:
        print("  ", e)
    print("RESULT:", result[:2500])


if __name__ == "__main__":
    main(sys.argv[1])
