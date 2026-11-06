---
name: aws-intent
description: >
  Intent phase of the AWS lifecycle: turn "what do you want to build" into requirements, non-functional
  requirements, a criticality tier, and one to three candidate architectures with trade-offs and one
  recommendation. Asks at most three or four clarifying questions, then routes each service choice to the
  domain router that owns it. Triggers on "I want to build X on AWS", "help me design", "which services
  should I use", "what architecture for", or any greenfield or new-feature request with the technology
  still open. Writes .aws-sdlc/intent.md. Not for writing code or IaC (use aws-build) and not for a
  request already committed to one service (route to that domain skill).
metadata:
  version: "1"
---

# AWS Intent

## Overview

The intent phase answers "what do you want to build, and what does it have to do". It produces a short,
reviewable `.aws-sdlc/intent.md`: functional requirements, non-functional requirements, a criticality
tier, one to three candidate architectures with trade-offs, and one recommendation. It does not write
code — that is `aws-build`. It does not pick low-level service options itself — it routes each decision to
the domain router that owns it.

The criticality tier set here (`prototype` / `internal` / `customer-facing` / `critical`) is read later by
`aws-orr` to scale the readiness review, so capture it deliberately.

**Works best with** the aws-core plugin installed (domain skills) and the AWS MCP Server (live docs and
sandboxed, audited AWS calls).

## When to use / not

Use for a greenfield build, a new feature on an existing workload, or any "which architecture / which
services" question where the technology is still open.

Do not use to:

- Write code or IaC → `aws-build`.
- Answer a question already scoped to one service → that domain skill (for example aws-database for a
  DynamoDB data-model question).
- Re-open a decision already recorded in `intent.md` unless the user brings new information.

## Workflow

1. **Read what exists.** If `.aws-sdlc/intent.md` is present, read it and treat this as a revision. Infer
   what you can from any code already in the project before asking anything.
2. **Ask at most three or four questions**, and only for facts that change the architecture. Prefer these,
   skipping any the user already supplied:
   - What does it do, and who uses it? (functional scope)
   - Scale and latency: expected request rate, data volume, and any latency target?
   - Data sensitivity and compliance: any PII, regulated data, or compliance regime?
   - Criticality: is this a throwaway prototype, an internal tool, customer-facing, or
     business-critical? (sets the tier) — and a rough budget and the team's existing skills if not clear.
   Never reply with questions alone and never exceed four; state your assumptions for anything unanswered.
3. **Capture requirements and NFRs.** Write functional requirements and NFRs (scale, latency, data
   sensitivity, compliance, budget, team skills) into the template. Copy every value the user stated
   (budget, rates, retention, Region) verbatim; never round or substitute a default. Record the criticality tier explicitly.
4. **Produce one to three candidate architectures.** For each, name the main services, the trade-off (cost,
   operational load, time to build, scale ceiling, lock-in), and what it optimizes for. Give exactly one
   recommendation with the reason the alternatives do not fit. Do not present neutral tables as the answer.
5. **Route each service choice to its domain router.** Do not pick the form factor or engine here — hand
   the decision to the owning skill (see [references/routing.md](references/routing.md)). Carry its
   recommendation back into the architecture.
6. **Ground the recommendation in live facts.** Before writing numbers, call the AWS MCP Server for the
   recommended option: `aws___get_regional_availability` for each main service in the target Region, and
   `aws___search_documentation` / `aws___read_documentation` for the pricing dimensions and any limit the
   design depends on (payload size, timeouts, throughput). In Claude Code these tools may be deferred; search
   for `aws-mcp` tools first. Record every source URL in the artifact's Sources section. If the server is
   unavailable, mark each figure as an unverified estimate.
7. **Offer the optional add-ons** when they apply: a cost estimate (aws-billing-and-cost-management), a
   threat model (threat-modeling-with-aws-security-agent, aws-agents-for-devsecops plugin), and startup
   context (architect-for-startups, aws-startup-advisor plugin).
8. **Write `.aws-sdlc/intent.md`** from [assets/intent-template.md](assets/intent-template.md). Set
   `status: complete` once the user accepts the recommendation, `draft` otherwise, and `next: aws-build`.

**Exit criteria:** `intent.md` exists with requirements, NFRs, a criticality tier, candidate
architectures, and one accepted recommendation.

## Routing

Route every service-level decision to the domain router that owns it; full table with reasons in
[references/routing.md](references/routing.md).

| Decision | Route to | Plugin |
|---|---|---|
| Compute: Lambda / event / HTTP / orchestration | `aws-serverless` | aws-core |
| Compute: EC2, long-running, batch, GPU | `aws-compute` | aws-core |
| Containers: ECS / EKS / Fargate | `aws-containers` | aws-core |
| Data store: SQL / NoSQL / cache | `aws-database` | aws-core |
| Object / file / block storage | `aws-storage` | aws-core |
| AI / ML / GenAI | `aws-ai-ml` | aws-core |
| Queues, streams, pub/sub | `aws-messaging-and-streaming` | aws-core |
| VPC, DNS, edge, connectivity | `aws-networking` | aws-core |
| Cost estimate vs budget | `aws-billing-and-cost-management` | aws-core |
| Trade-off review across pillars | `aws-well-architected-review` | aws-core |
| Threat model | `threat-modeling-with-aws-security-agent` | aws-agents-for-devsecops |
| Startup-specific guidance | `architect-for-startups` | aws-startup-advisor |

## Artifact

Writes `.aws-sdlc/intent.md` from [assets/intent-template.md](assets/intent-template.md). Phase best
practices (which NFRs matter, how to scope by criticality) are in
[references/best-practices.md](references/best-practices.md).

## Using the AWS MCP Server

This plugin configures the AWS MCP Server. Prefer its tools over the local AWS CLI when they are available:

- `aws___search_documentation`, `aws___read_documentation`, `aws___get_regional_availability`, `aws___list_regions`: live facts (limits, pricing, regions, new launches). No credentials needed.
- `aws___run_script`: sandboxed Python with `await call_boto3(service_name=..., operation_name=...)` (see the tool description for parameters) under the user's IAM credentials. Every call is logged in CloudTrail and carries the `aws:ViaAWSMCPService` / `aws:CalledViaAWSMCP` condition keys, so agent actions stay auditable.
- `aws___retrieve_skill(skill_name=...)`: load a routed skill that is not installed locally (pass `file="references/..."` for its reference files).

Use the documentation tools for limits, pricing and regional availability of every candidate. Use `aws___run_script` only for read-only discovery of what already exists in the account (VPCs, existing tables, quotas). If the MCP server is not connected, fall back to the AWS CLI with the same read-only-by-default rule.

## Rules

- **Every endpoint that returns non-public data has real authentication.** Name the auth model per caller
  (machine-to-machine such as a signed webhook, versus people such as a support team) in the architecture.
  An unguessable URL, "shared only internally", or an IP that is not enforced is not access control; reject
  any option that relies on it.
- **Recommend, do not mandate.** Present options with trade-offs and make one opinionated recommendation
  with a reason the alternatives do not fit. Never hand back a neutral comparison as the answer.
- **Route, do not duplicate.** Defer every service-level choice to the domain router; do not re-derive it
  here.
- **Ask little.** At most three or four questions, only for facts that change the architecture; state
  assumptions for the rest and never reply with questions alone.
- **Set the criticality tier explicitly** — `aws-orr` scales its review by it.
- **Ground facts in live docs.** For limits, pricing, regional availability, or newly launched features,
  use the AWS MCP Server tools (`search_documentation`, `read_documentation`, `get_regional_availability`)
  rather than training data.
- **No mutating AWS calls without explicit user confirmation.** Intent is a planning phase; a cost
  estimate uses read-only pricing lookups.
- **Degrade gracefully.** If a routed skill is not installed, still give the architecture answer and name
  the skill that would go deeper.
