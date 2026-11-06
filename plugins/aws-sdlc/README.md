# aws-sdlc

Lifecycle-first skills for building on AWS. Instead of starting from a service ("use the Lambda skill"),
the agent starts from where you are in the software lifecycle and routes to service skills only when it
needs depth.

```text
aws-intent ─► aws-build ─► aws-verify ─► aws-orr ─► aws-deploy ─► aws-maintain
     ▲                                      ▲                         │
     └──────────── new feature ─────────────┴──── readiness drift ────┘
```

| Skill | Phase | What it does | Writes |
|---|---|---|---|
| [aws-sdlc](skills/aws-sdlc/) | Entry | Finds the phase from your wording and existing artifacts, hands off | — |
| [aws-intent](skills/aws-intent/) | Intent | Requirements, non-functional requirements, criticality tier, 1–3 candidate architectures with trade-offs, one recommendation | `.aws-sdlc/intent.md` |
| [aws-build](skills/aws-build/) | Build | IaC and app code from the intent, least-privilege IAM, secrets, small increments that synth | `.aws-sdlc/build.md` |
| [aws-verify](skills/aws-verify/) | Verify | Static checks, IAM review, security scan, tests, cost vs budget, resilience; PASS/FAIL/SKIPPED with evidence | `.aws-sdlc/verify-report.md` |
| [aws-orr](skills/aws-orr/) | Operational readiness | GREEN/YELLOW/RED review of ownership, alarms, runbooks, rollback, resilience, security, cost guardrails, scaled to criticality. Any RED blocks a production deploy | `.aws-sdlc/orr.md` |
| [aws-deploy](skills/aws-deploy/) | Deploy | Environments, diff/change-set preview, staged rollout, rollback plan, CI/CD; refuses prod without a passing ORR | `.aws-sdlc/deploy-record.md` |
| [aws-maintain](skills/aws-maintain/) | Maintain | Incident triage, observability gaps, cost, security and upgrades; periodic ORR re-runs | `.aws-sdlc/maintain-log.md` |

## Design rules

- **Recommend, don't mandate.** Phase skills present options with trade-offs and make one recommendation with a reason. Service choices go to the domain routers in `aws-core` (`aws-serverless`, `aws-compute`, `aws-containers`, `aws-database`, …).
- **Route, don't duplicate.** Each phase skill has `references/routing.md` mapping signals to the existing skill that owns the detail, and `references/best-practices.md` with the practices that matter in that phase.
- **Artifacts are the handoff.** Each phase writes a small markdown file under `.aws-sdlc/` that the next phase reads. Every phase also works on its own when upstream artifacts are missing.
- **Live facts.** Limits, pricing, regional availability and new launches come from the AWS MCP Server documentation tools, not training data.

Works best with the [aws-core](../aws-core/) plugin installed. Some routes point to skills in
[aws-agents-for-devsecops](../aws-agents-for-devsecops/) and [aws-startup-advisor](../aws-startup-advisor/).

## Try it from a local checkout

No marketplace publish needed:

```bash
tools/dev/setup-demo.sh            # creates /tmp/aws-sdlc-demo with a Kiro agent config
cd /tmp/aws-sdlc-demo

# Claude Code: load both plugins from the checkout for this session
claude --plugin-dir <repo>/plugins/aws-sdlc --plugin-dir <repo>/plugins/aws-core

# Kiro CLI: agent that loads only this checkout's skills plus the AWS MCP Server
kiro-cli chat --agent aws-sdlc-demo
```

Or install from the fork as a marketplace in Claude Code:

```text
/plugin marketplace add PCManticore/agent-toolkit-for-aws     # or a local path
/plugin install aws-sdlc@agent-toolkit-for-aws
```

`tools/dev/smoke-test.sh` sends one prompt each for intent, ORR and maintain through headless Claude Code and checks that the matching phase skill was invoked.

## Skill sources

Canonical sources live in [`skills/sdlc-skills/`](../../skills/sdlc-skills/). Run `python3 tools/sync-plugin-skills.py --plugin aws-sdlc` after editing them.
