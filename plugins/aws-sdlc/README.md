# aws-sdlc

Lifecycle-first skills for building on AWS. Instead of starting from a service ("use the Lambda skill"),
the agent starts from where you are in the software lifecycle and routes to service skills only when it
needs depth.

```text
aws-intent ─► aws-build ─► aws-verify ─► aws-readiness ─► aws-deploy ─► aws-maintain
     ▲                                      ▲                         │
     └──────────── new feature ─────────────┴──── readiness drift ────┘
```

| Skill | Phase | What it does | Writes |
|---|---|---|---|
| [aws-sdlc](skills/aws-sdlc/) | Entry | Finds the phase from your wording and existing artifacts, hands off | — |
| [aws-intent](skills/aws-intent/) | Intent | Requirements, non-functional requirements, criticality tier, 1–3 candidate architectures with trade-offs, one recommendation | `.aws-sdlc/intent.md` |
| [aws-build](skills/aws-build/) | Build | IaC and app code from the intent, least-privilege IAM, secrets, small increments that synth | `.aws-sdlc/build.md` |
| [aws-verify](skills/aws-verify/) | Verify | Static checks, IAM review, security scan, tests, cost vs budget, resilience; PASS/FAIL/SKIPPED with evidence | `.aws-sdlc/verify-report.md` |
| [aws-readiness](skills/aws-readiness/) | Operational readiness | GREEN/YELLOW/RED review of ownership, alarms, runbooks, rollback, resilience, security, cost guardrails, scaled to criticality. Any RED blocks a production deploy | `.aws-sdlc/readiness.md` |
| [aws-deploy](skills/aws-deploy/) | Deploy | Environments, diff/change-set preview, staged rollout, rollback plan, CI/CD; refuses prod without a passing readiness review | `.aws-sdlc/deploy-record.md` |
| [aws-maintain](skills/aws-maintain/) | Maintain | Incident triage, observability gaps, cost, security and upgrades; periodic readiness review re-runs | `.aws-sdlc/maintain-log.md` |

## Design rules

- **Recommend, don't mandate.** Phase skills present options with trade-offs and make one recommendation with a reason. Service choices go to the domain routers in `aws-core` (`aws-serverless`, `aws-compute`, `aws-containers`, `aws-database`, …).
- **Route, don't duplicate.** Each phase skill has `references/routing.md` mapping signals to the existing skill that owns the detail, and `references/best-practices.md` with the practices that matter in that phase.
- **Artifacts are the handoff.** Each phase writes a small markdown file under `.aws-sdlc/` that the next phase reads. Every phase also works on its own when upstream artifacts are missing.
- **Live facts.** Limits, pricing, regional availability and new launches come from the AWS MCP Server documentation tools, not training data.

Works best with the [aws-core](../aws-core/) plugin installed. Some routes point to skills in
[aws-agents-for-devsecops](../aws-agents-for-devsecops/) and [aws-startup-advisor](../aws-startup-advisor/).

## Try it from a local checkout

No marketplace publish needed. `tools/dev/setup-demo.sh` creates a workspace where Claude Code and Kiro
CLI see only these seven skills (your personal skills and plugins are not loaded), tools are
auto-approved, and every demo prompt is a slash command:

```bash
tools/dev/setup-demo.sh /path/to/demo-run
cd /path/to/demo-run
./claude-demo      # or ./kiro-demo
```

Domain skills (`aws-serverless`, `aws-lambda-durable-functions`, `aws-lambda-web-functions`, ...) are
loaded on demand from the AWS MCP Server with `retrieve_skill`. Full run sheet: [demo/README.md](../../demo/README.md).

## Example prompts (one per phase)

| Phase | Prompt |
|---|---|
| intent | *I want a tiny web page where someone types the name of an AWS service and gets a short plain-English explanation that streams in word by word. Node.js, no database, no login, us-west-2, a few dollars a month. It's a prototype.* |
| build | *Build it as small as possible: one index.js with Express, no infrastructure-as-code. Run it locally on port 8787. Don't deploy yet.* |
| verify | *Verify it before we ship. Keep it local and check the IAM permissions are least privilege.* |
| readiness | *We'll share the link with the team this afternoon. Are we ready?* |
| deploy | *Ship it.* (refused while the readiness review is blocked) |
| maintain | *People say some answers stop halfway through. Triage it.* |

Plain Claude Code without the demo workspace: `claude --plugin-dir plugins/aws-sdlc`, or
`/plugin marketplace add PCManticore/agent-toolkit-for-aws` then `/plugin install aws-sdlc@agent-toolkit-for-aws`.
`tools/dev/smoke-test.sh` checks that intent, readiness review and maintain prompts reach the right phase skill.

## Skill sources

Canonical sources live in [`skills/sdlc-skills/`](../../skills/sdlc-skills/). Run `python3 tools/sync-plugin-skills.py --plugin aws-sdlc` after editing them.
