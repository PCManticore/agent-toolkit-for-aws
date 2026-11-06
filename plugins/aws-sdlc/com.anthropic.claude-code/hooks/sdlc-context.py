#!/usr/bin/env python3
"""UserPromptSubmit hook: keep the agent on the AWS SDLC lifecycle.

When the project has a .aws-sdlc/ directory, inject a short note naming the
artifacts that exist, the phase the newest artifact points to, and an instruction
to load the matching phase skill before acting. Without this, agents that already
"know" how to write CDK or deploy a stack skip the phase skill and its gates
(for example the ORR gate in aws-deploy).

Prints nothing (no-op) when .aws-sdlc/ does not exist. Never fails the prompt.
"""
import json
import os
import re
import sys
from pathlib import Path

PHASES = ["intent", "build", "verify-report", "orr", "deploy-record", "maintain-log"]


def read_header(path: Path) -> dict:
    """Return the YAML-ish front-matter keys of an artifact (phase, status, next)."""
    text = path.read_text(errors="replace")[:2000]
    match = re.match(r"---\n(.*?)\n---", text, re.S)
    header = {}
    if match:
        for line in match.group(1).splitlines():
            key, _, value = line.partition(":")
            header[key.strip()] = value.strip()
    return header


def main() -> None:
    try:
        payload = json.load(sys.stdin) if not sys.stdin.isatty() else {}
    except ValueError:
        payload = {}
    cwd = Path(payload.get("cwd") or os.getcwd())
    sdlc = cwd / ".aws-sdlc"
    if not sdlc.is_dir():
        return

    present = []
    for name in PHASES:
        path = sdlc / f"{name}.md"
        if path.exists():
            present.append((name, path.stat().st_mtime, read_header(path)))
    if not present:
        return

    newest = max(present, key=lambda item: item[1])
    summary = ", ".join(f"{n}.md ({h.get('status', '?')})" for n, _, h in present)
    next_skill = newest[2].get("next", "aws-sdlc")
    orr = next((h for n, _, h in present if n == "orr"), None)

    lines = [
        "This project follows the AWS SDLC lifecycle (aws-sdlc plugin).",
        f"Artifacts in .aws-sdlc/: {summary}.",
        f"The newest artifact ({newest[0]}.md) points to the `{next_skill}` skill.",
        "Before writing code, running AWS commands, or answering, load the phase skill that matches "
        "the user's request (aws-intent, aws-build, aws-verify, aws-orr, aws-deploy, aws-maintain; "
        f"use `{next_skill}` if the request is to continue) and follow its workflow and artifact contract.",
    ]
    if orr is None or orr.get("status") == "blocked":
        lines.append("Production deploys are gated: orr.md is " + ("missing." if orr is None else "blocked."))

    if "--plain" in sys.argv:  # Kiro CLI hooks add stdout to context as-is
        print("\n".join(lines))
        return
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": "\n".join(lines),
        }
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:  # never block the user's prompt because of this hook
        pass
