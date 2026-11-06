---
name: aws-orr
description: >-
  Use whenever someone asks if an AWS workload is ready for production, launch or go-live, including
  "are we operationally ready", "ready to launch", "what should we check before prod", "ORR",
  "production readiness", "go-live checklist". Runs an Operational Readiness Review: scores ownership,
  observability, alarming, runbooks, deployment safety, resilience, security, dependencies, load testing and
  cost guardrails GREEN/YELLOW/RED with evidence, scaled to the workload's criticality. Writes .aws-sdlc/orr.md;
  any RED blocks aws-deploy from production. Not for a full architecture review (aws-well-architected-review)
  or the deploy itself (aws-deploy).
metadata:
  version: "1"
---

# AWS ORR (Operational Readiness Review)

Gate a workload before its first production deploy, and re-check it as it drifts.
This skill scores readiness against a checklist, grounds each score in evidence,
and writes a verdict that `aws-deploy` reads before it will touch production.

**Works best with** the aws-core plugin installed (domain skills) and the
[AWS MCP server](https://docs.aws.amazon.com/aws-mcp/) for read-only account
checks. All guidance also works with standard AWS CLI access.

## When to use

- Before the first production deploy of a workload (the gate).
- After a major change, incident, or dependency addition.
- On a schedule, driven by `aws-maintain`, to catch readiness drift.
- Standalone: run it even if no upstream `.aws-sdlc/` artifacts exist — infer
  what you need from the code and account, or ask the 1–3 questions you need.

## When not to use

- Writing IaC or app code — use `aws-build`.
- Pre-ship checks (synth, lint, tests, cost estimate) — use `aws-verify`.
- Running the deploy — use `aws-deploy`.
- A broad design review across all six pillars — use `aws-well-architected-review`.

## Workflow

1. **Read inputs.** Load `.aws-sdlc/intent.md`, `build.md`, and `verify-report.md`
   if present. Take the criticality tier from `intent.md`
   (prototype / internal / customer-facing / critical). If it is missing, ask once,
   or infer from blast radius (who is harmed if this breaks) and default to
   `internal`. *Exit:* tier is fixed.
2. **Pick the item set.** Scale the checklist by tier so a prototype is not drowned
   in items: prototype ≈ 8 core items, internal adds operability, customer-facing
   adds resilience and security depth, critical runs the full list. See
   [references/checklist.md](references/checklist.md). *Exit:* the item list is chosen.
3. **Score each item.** For every item, gather evidence — a file in the repo or a
   **read-only** AWS check (`describe`/`list` via the AWS MCP Server or CLI; never a
   mutating call). Assign GREEN (evidence shows it is met), YELLOW (partially met or
   planned), or RED (not met, no evidence). Record the evidence next to the score.
   *Exit:* every item has a score and a line of evidence.
4. **Route the gaps.** For each YELLOW or RED, name the skill that closes it
   (see [references/routing.md](references/routing.md)) and, for YELLOW, record an
   explicit owner and target date. *Exit:* each gap has a route and, if YELLOW, an owner+date.
5. **Write the verdict.** Fill [assets/orr-template.md](assets/orr-template.md) into
   `.aws-sdlc/orr.md`. Set `status: blocked` if any item is RED, else `complete`.
   *Exit:* `orr.md` written with a header block and per-item scores.
6. **Re-run mode (from maintain).** If an `orr.md` already exists, diff against it:
   report which items changed colour, which regressed to RED, and which new items
   the current tier added. *Exit:* the diff is in the new `orr.md`.

## Routing

Each gap routes to the skill that owns the fix. Full table with reasons:
[references/routing.md](references/routing.md).

| Gap area | Route to | Plugin |
|---|---|---|
| Alarms + notifications | `setting-up-cloudwatch-alarm-notifications` | specialized (operations-skills) |
| Metrics, logs, traces, dashboards | `aws-observability`, `setting-up-cloudwatch-observability` | aws-core + specialized (operations-skills) |
| Audit trail | `setting-up-cloudtrail-multi-region` | specialized (operations-skills) |
| Resilience, backups, failure injection | `resilience-hub-getting-started`, `resilience-hub-failure-mode-assessment`, `aws-fault-injection-service` | specialized (resilience-skills) |
| Security posture, encryption, secrets | `aws-security` | aws-core |
| Least-privilege IAM | `aws-iam` | aws-core |
| Budgets and cost alerts | `aws-billing-and-cost-management` | aws-core |
| Release-readiness test analysis | `analyzing-release-readiness` | aws-agents-for-devsecops |
| Broad pillar review | `aws-well-architected-review` | aws-core |

## Artifact

Writes `.aws-sdlc/orr.md` from [assets/orr-template.md](assets/orr-template.md).
`next: aws-deploy`. A blocked `orr.md` stops a production deploy.

## Using the AWS MCP Server

This plugin configures the AWS MCP Server. Prefer its tools over the local AWS CLI when they are available:

- `aws___search_documentation`, `aws___read_documentation`, `aws___get_regional_availability`, `aws___list_regions`: live facts (limits, pricing, regions, new launches). No credentials needed.
- `aws___run_script`: sandboxed Python with `await call_boto3(service_name=..., operation_name=...)` (see the tool description for parameters) under the user's IAM credentials. Every call is logged in CloudTrail and carries the `aws:ViaAWSMCPService` / `aws:CalledViaAWSMCP` condition keys, so agent actions stay auditable.
- `aws___retrieve_skill(skill_name=...)`: load a routed skill that is not installed locally (pass `file="references/..."` for its reference files).

Gather live evidence with read-only `aws___run_script` calls (describe/list/get only), batching related checks into one script per ORR area, and cite the API calls in each item's evidence. If the MCP server is not connected, fall back to the AWS CLI with the same read-only-by-default rule.

## Rules

- **Recommend, don't mandate.** Where a gap has several fixes, give options with
  trade-offs and one recommendation with a reason; defer service choices to domain skills.
- **Route, don't duplicate.** Point at the owning skill rather than re-deriving its content.
- **Read-only only.** Gather account evidence with `describe`/`list`. Never run a
  mutating AWS call, and never run any AWS call, read or write, without the user's go-ahead.
- **Ground facts in live sources.** Confirm limits, quotas, regional availability and
  new-feature behaviour via the AWS MCP Server tools (`search_documentation`,
  `read_documentation`, `get_regional_availability`), not training data.
- **Evidence or it did not happen.** No GREEN without a file or a read-only check behind it.
- **RED blocks; YELLOW needs an owner.** Any RED → `status: blocked`. Every YELLOW
  carries an explicit owner and date.
- **Degrade gracefully.** If a routed skill is not installed, still give the readiness
  finding and name the skill that would go deeper.
