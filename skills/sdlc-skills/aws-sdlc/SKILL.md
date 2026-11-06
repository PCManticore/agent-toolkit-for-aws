---
name: aws-sdlc
description: >
  Entry router for the AWS software lifecycle. Detects which phase the user is in — intent, build,
  verify, operational readiness, deploy, or maintain — from their wording and from which .aws-sdlc/*.md
  artifacts already exist, shows the lifecycle map, and hands off to the matching phase skill. Triggers
  on "where do I start", "what's next", "build on AWS", "ship this", "is this production ready", "deploy",
  "operate", or any request that spans more than one phase. Not for a service- or technology-specific
  question already scoped to one area — route straight to the domain skill (aws-serverless, aws-compute,
  aws-database) or the matching phase skill instead.
metadata:
  version: "1"
---

# AWS SDLC

## Overview

This skill is the front door for building and running a workload on AWS. It does one thing: work out
which lifecycle phase the request belongs to, then hand off to the phase skill that owns it. It writes
no artifacts of its own and does not do the phase work itself.

The lifecycle has six phases and loops:

```
intent → build → verify → readiness → deploy → maintain
                                                  │
                      new feature ────────────────┘  (back to intent)
                      readiness drift ────────────┘  (back to readiness)
```

Each phase skill reads the artifact the previous phase wrote under `.aws-sdlc/` in the user's project
root and writes its own. The chain is a convenience, not a requirement: every phase skill also runs
standalone and asks or infers what it needs when upstream artifacts are missing.

**Works best with** the aws-core plugin installed (domain skills) and the AWS MCP Server (live docs and
sandboxed, audited AWS calls).

## When to use / not

Use when the request spans phases or does not name one ("help me build X on AWS", "what do I do next",
"get this ready for production"). Use when you need to orient someone who does not know the lifecycle.

Do not use when the request is already scoped to one phase or one domain — route directly:

- A specific service or technology question → the domain skill (for example aws-serverless, aws-database).
- A request clearly inside one phase → that phase skill (see the table below).

## Workflow

1. **Read the artifact state.** List `.aws-sdlc/` in the project root. Each file present means that phase
   has run; read its frontmatter `status` (`draft` / `complete` / `blocked`) and `next` field.
2. **Read the wording.** Match the request against the phase signals in
   [references/routing.md](references/routing.md).
3. **Pick the phase.** Combine both signals — artifacts show how far the work has gone, wording shows
   what the user wants now. When they disagree, the wording wins; say what you see and confirm.
   - No artifacts and a "what should I build" request → `aws-intent`.
   - `intent.md` exists, user wants code → `aws-build`.
   - Code exists, user wants to check it before shipping → `aws-verify`.
   - User asks "is this production ready" or wants the gate → `aws-readiness`.
   - `readiness.md` is `complete` and user wants to ship → `aws-deploy`.
   - Live workload, user asks about alarms, cost, incidents, upgrades → `aws-maintain`.
4. **Show the map and hand off.** Tell the user the detected phase, show the one-line lifecycle map, name
   the phase skill, and hand off. If that skill is not installed, say so and give the phase's first step
   yourself.

**Exit criteria:** the user knows which phase they are in, and the owning phase skill has been invoked
(or its first step given when the skill is absent).

## Routing

Phase skills are part of this `aws-sdlc` plugin. Short version below; full signal table with reasons in
[references/routing.md](references/routing.md).

| Signal | Phase skill | Artifact it writes |
|---|---|---|
| "what should I build", requirements, architecture choice | `aws-intent` | `.aws-sdlc/intent.md` |
| "write the code / IaC", scaffold, implement | `aws-build` | `.aws-sdlc/build.md` |
| "check before shipping", lint, test, least-privilege, cost vs budget | `aws-verify` | `.aws-sdlc/verify-report.md` |
| "production ready?", readiness gate | `aws-readiness` | `.aws-sdlc/readiness.md` |
| "deploy", rollout, change set, rollback, pipeline | `aws-deploy` | `.aws-sdlc/deploy-record.md` |
| "operate", alarms, incident, cost, upgrades | `aws-maintain` | `.aws-sdlc/maintain-log.md` |

`aws-deploy` is the phase skill; it routes to the core `aws-deployment` skill for CodePipeline /
CodeBuild / CodeDeploy mechanics. They are different things — do not confuse them.

## Artifact

This skill writes nothing. It reads the `.aws-sdlc/` artifacts to detect the phase. The artifact header
every phase skill writes is:

```markdown
---
phase: intent|build|verify|readiness|deploy|maintain
status: draft|complete|blocked
updated: <ISO date>
inputs: [list of upstream artifacts read]
next: <next phase skill name>
---
```

## Using the AWS MCP Server

This plugin configures the AWS MCP Server. Prefer its tools over the local AWS CLI when they are available:

- `aws___search_documentation`, `aws___read_documentation`, `aws___get_regional_availability`, `aws___list_regions`: live facts (limits, pricing, regions, new launches). No credentials needed.
- `aws___run_script`: sandboxed Python with `await call_boto3(service_name=..., operation_name=...)` (see the tool description for parameters) under the user's IAM credentials. Every call is logged in CloudTrail and carries the `aws:ViaAWSMCPService` / `aws:CalledViaAWSMCP` condition keys, so agent actions stay auditable.
- `aws___retrieve_skill(skill_name=...)`: load a routed skill that is not installed locally (pass `file="references/..."` for its reference files). When a phase routes to a skill, load it (locally or through `aws___retrieve_skill`) before acting in its domain; do not work from memory, because services launched after the model's training cutoff are where memory is wrong.

Read the account only to detect state (for example, whether a stack named in `build.md` exists). If the MCP server is not connected, fall back to the AWS CLI with the same read-only-by-default rule.

## Rules

- **End every reply with the next step.** Last line: `Next → <phase skill>: say "<example prompt>"` for the phase you handed off to.
- **Route, do not duplicate.** Hand off to the phase skill; do not do the phase work here.
- **Recommend, do not mandate.** When you suggest an entry phase, give the reason and let the user override.
- **Detect, do not assume.** Base the phase on both the `.aws-sdlc/` artifacts and the wording; when they
  conflict, follow the wording and say what you saw.
- **Degrade gracefully.** If a phase skill is not installed, still name the phase, give its first step, and
  name the skill that would go deeper.
- **Ground facts in live docs.** For limits, pricing, regional availability, or newly launched features,
  use the AWS MCP Server tools (`search_documentation`, `read_documentation`, `get_regional_availability`)
  rather than training data.
- **No mutating AWS calls without explicit user confirmation.**
