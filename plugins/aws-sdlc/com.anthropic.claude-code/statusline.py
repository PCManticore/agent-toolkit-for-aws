#!/usr/bin/env python3
"""Claude Code status line for the AWS SDLC skills.

Shows the lifecycle with each phase's state, read from the .aws-sdlc/ artifacts in
the project, plus what to type next:

  AWS SDLC  ✓ intent ─ ✓ build ─ ● verify ─ ○ orr ─ ○ deploy ─ ○ maintain   next ▸ "verify it"

Configure in .claude/settings.json:
  "statusLine": {"type": "command", "command": "python3 /path/to/statusline.py"}
"""
import json
import os
import re
import sys
from pathlib import Path

# phase label, artifact file, what to type to run it
PHASES = [
    ("intent", "intent.md", "describe what you want to build"),
    ("build", "build.md", "build it"),
    ("verify", "verify-report.md", "verify it before we ship"),
    ("orr", "orr.md", "are we ready for production?"),
    ("deploy", "deploy-record.md", "ship it to production"),
    ("maintain", "maintain-log.md", "how is it doing in production?"),
]

ORANGE, GREEN, RED, DIM, BOLD, RESET = (
    "\033[38;5;214m", "\033[38;5;120m", "\033[38;5;203m", "\033[38;5;250m", "\033[1m", "\033[0m")


def status_of(path: Path) -> str:
    """Return the artifact's front-matter status, or '' when it does not exist."""
    if not path.exists():
        return ""
    match = re.search(r"^status:\s*(\S+)", path.read_text(errors="replace")[:1000], re.M)
    return match.group(1).lower() if match else "complete"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}
    cwd = Path((data.get("workspace") or {}).get("current_dir") or data.get("cwd") or os.getcwd())
    sdlc = cwd / ".aws-sdlc"

    states = [status_of(sdlc / f) for _, f, _ in PHASES]
    # Current phase: the first one not done; maintain once deployed.
    current = next((i for i, s in enumerate(states) if s in ("", "draft")), len(PHASES) - 1)
    hint = PHASES[current][2]
    orr_blocked = states[3] == "blocked"
    if orr_blocked:
        current, hint = 3, "fix the ORR blockers and re-run the review"
    elif states[1] and states[2] in ("fail", "failed"):
        current, hint = 1, "fix the verify failures, then verify again"

    parts = []
    for i, (label, _, _) in enumerate(PHASES):
        state = states[i]
        if i == current:
            mark = f"{RED}✗" if (i == 3 and orr_blocked) else f"{ORANGE}{BOLD}●"
            parts.append(f"{mark} {label}{RESET}")
        elif state and state not in ("draft", "blocked", "fail", "failed"):
            parts.append(f"{GREEN}✓ {label}{RESET}")
        else:
            parts.append(f"{DIM}○ {label}{RESET}")
    line = f"{ORANGE}{BOLD}AWS SDLC{RESET}  " + f" {DIM}─{RESET} ".join(parts)
    print(f"{line}   {DIM}next ▸{RESET} {BOLD}\"{hint}\"{RESET}")


if __name__ == "__main__":
    try:
        main()
    except Exception:  # a status line must never break the session
        print("AWS SDLC")
