---
name: aws-maintain
description: >-
  Use whenever a workload already running on AWS needs attention: it is erroring, throwing 5xx, slow,
  timing out, an alarm is firing, the bill went up, a runtime or engine version is being deprecated, or
  someone asks how to triage, operate or keep it healthy ("how should we triage", "it's down", "latency
  spike", "day-2 ops"). Maintain phase: picks one of four loops (incident triage, observability gaps, cost,
  security and upgrades), works evidence-first and read-only by default, and routes to aws-investigation,
  troubleshooting-application-failures and other domain skills for depth. Appends to .aws-sdlc/maintain-log.md.
  Not for designing something new (aws-intent) or shipping a change (aws-deploy).
metadata:
  version: "1"
---

# AWS Maintain

The maintain phase keeps a deployed workload healthy, cheap, and secure, and feeds changes back
into the lifecycle. It does not diagnose or fix in depth itself - it runs a short triage, then
routes to the domain and service skills that own each area.

Works best with the aws-core plugin installed (domain skills) and the AWS MCP Server.

## When to use

- A workload is live and something needs attention: an incident, an alarm, a cost jump, a security
  or deprecation concern.
- You want to close observability or readiness gaps after a deploy.
- Periodic operation: scheduled health, cost, and security review.

## When not to use

- Deciding what to build or re-architecting -> **aws-intent**.
- Writing application code or IaC -> **aws-build**.
- Pre-ship synth/lint/test/cost checks -> **aws-verify**.
- The production readiness gate -> **aws-orr**.
- Rolling out a change -> **aws-deploy**.

## Workflow

### 1. Load context

Read `.aws-sdlc/deploy-record.md` if it exists (what shipped, where, resources, rollback plan) and
`.aws-sdlc/intent.md` for criticality. Missing? Ask the 1-3 facts you need: what the workload is,
which account/region, and how critical it is. Do not refuse for lack of upstream artifacts.

Exit: you know the workload, its environment, and which loop applies.

### 2. Pick the loop

Match the request to one loop (ask only if ambiguous):

| Signal | Loop |
|---|---|
| broken, down, slow, erroring, alarm firing, timeout, 5xx | 1 - Incident / triage |
| no alarms, blind spots, "can't see what's happening", missing dashboards | 2 - Health / observability |
| bill up, over budget, idle resources, right-sizing | 3 - Cost / efficiency |
| runtime EOL, engine version, CVE, drift from least-privilege, "still secure?" | 4 - Security / upgrades |

Exit: one loop selected.

### 3. Run the loop (evidence first)

**Loop 1 - Incident / triage.** Stay read-only by default. Collect evidence before hypotheses:
metrics, then logs, then traces. Establish impact (scope, start time, customer effect), form a
cause from what you read, then propose a fix and get explicit confirmation before any mutating
call. Route per the table below.

**Loop 2 - Health / observability.** Find what is not measured: metrics without alarms, alarms
without actions, missing dashboards, no tracing. Recommend the minimum set that covers
customer-impacting signals. Route to the observability skills.

**Loop 3 - Cost / efficiency.** Read current spend and the largest line items before suggesting
anything. Separate waste (idle, oversized, untagged) from structural cost. Recommend changes with
the saving and the risk. Route to **aws-billing-and-cost-management**.

**Loop 4 - Security / upgrades.** Check runtime and engine versions against end-of-life dates,
IAM against least-privilege, encryption, secrets handling, and public exposure. Ground EOL dates,
supported versions, and newly launched replacements in live AWS docs, not memory. Route to the
security and service skills.

Exit: findings recorded with evidence; fixes proposed (not applied) unless confirmed.

### 4. Re-run readiness and route the change

- Periodically, or after any major change, re-run **aws-orr** and diff against the last `orr.md`.
  New RED or YELLOW items are maintain findings.
- A fix that changes architecture loops back to **aws-intent**.
- A code or config fix goes **aws-build -> aws-verify -> aws-deploy**.
- Append a dated entry to `.aws-sdlc/maintain-log.md` for every loop you run (see Artifact).

Exit: `maintain-log.md` updated; any follow-on phase named.

## Routing

Signal -> existing skill. Full table with the "why": [references/routing.md](references/routing.md).

| Loop | Route to |
|---|---|
| Incident, cross-service trace | **aws-investigation** (core) |
| App errors/5xx | **troubleshooting-application-failures** (specialized) |
| Lambda timeouts | **debugging-lambda-timeouts** (specialized) |
| Agent-led incident | **investigating-incidents-with-aws-devops-agent** (aws-agents-for-devsecops) |
| Metrics/logs/traces, dashboards | **aws-observability** (core) |
| Alarm actions/notifications | **setting-up-cloudwatch-alarm-notifications** (specialized) |
| Observability setup | **setting-up-cloudwatch-observability** (specialized) |
| Cost | **aws-billing-and-cost-management** (core) |
| Security posture | **aws-security** (core) |
| IAM least-privilege | **aws-iam** (core) |
| Readiness drift | **aws-orr** (sdlc) |

If a routed skill is not installed, still give the phase answer and name the skill that would go
deeper.

## Artifact

Appends dated entries to `.aws-sdlc/maintain-log.md`. Template:
[assets/maintain-log-template.md](assets/maintain-log-template.md). Each entry records the loop,
the evidence, the finding, and the action or route taken.

## Using the AWS MCP Server

This plugin configures the AWS MCP Server. Prefer its tools over the local AWS CLI when they are available:

- `aws___search_documentation`, `aws___read_documentation`, `aws___get_regional_availability`, `aws___list_regions`: live facts (limits, pricing, regions, new launches). No credentials needed.
- `aws___run_script`: sandboxed Python with `await call_boto3(service_name=..., operation_name=...)` (see the tool description for parameters) under the user's IAM credentials. Every call is logged in CloudTrail and carries the `aws:ViaAWSMCPService` / `aws:CalledViaAWSMCP` condition keys, so agent actions stay auditable.
- `aws___retrieve_skill(skill_name=...)`: load a routed skill that is not installed locally (pass `file="references/..."` for its reference files). When a phase routes to a skill, load it (locally or through `aws___retrieve_skill`) before acting in its domain; do not work from memory, because services launched after the model's training cutoff are where memory is wrong.

Pull metrics, logs and traces with read-only `aws___run_script` calls (CloudWatch `get_metric_data`, Logs Insights `start_query`/`get_query_results`, `describe_alarms`). Propose fixes; run a mutating call only after the user confirms. If the MCP server is not connected, fall back to the AWS CLI with the same read-only-by-default rule.

## Rules

- **End every reply with the next step.** Last line, exactly this shape: `Next → aws-orr or aws-intent: say "Re-run the readiness review. (or describe the next feature)"`. If this phase is blocked or failed, name the fix instead (for example `Next → fix the 3 RED items, then re-run the review`).
- **Recommend, don't mandate.** Give options with trade-offs, make one recommendation, say why.
- **Route, don't duplicate.** Hand off to the owning skill rather than re-deriving its content.
- **Evidence first.** In triage, read metrics/logs/traces before forming a cause; label anything
  you did not read as unverified.
- **Read-only by default.** Propose fixes; never run a mutating AWS call without explicit user
  confirmation.
- **Ground facts in live docs.** Service limits, pricing, regional availability, EOL dates, and
  newly launched features come from the AWS MCP Server tools (`search_documentation`,
  `read_documentation`, `get_regional_availability`), not training data.
- **Loop back, don't patch blind.** Architecture change -> aws-intent; code/config fix ->
  aws-build -> aws-verify -> aws-deploy; readiness drift -> re-run aws-orr.
- Best practices for this phase: [references/best-practices.md](references/best-practices.md).
