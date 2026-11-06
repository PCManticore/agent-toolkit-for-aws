# aws-intent best practices

The intent phase maps most closely to the Well-Architected **Operational Excellence** and **Cost
Optimization** pillars: understand the workload and its business value before choosing technology, and
make cost a design input rather than a surprise. Keep the output short and reviewable.

Reference: <https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html>

## Capture the non-functional requirements that change the architecture

Ask about an NFR only when it moves the decision. The ones that usually do:

- **Scale** — steady-state and peak request rate, data volume, growth. Decides serverless vs provisioned,
  and single-table vs relational.
- **Latency** — a target (p50/p99) or "interactive vs batch". Decides caching, edge, and sync vs async.
- **Data sensitivity** — PII, PHI, PCI, regulated data. Decides encryption, isolation, and region.
- **Compliance** — HIPAA, PCI-DSS, FedRAMP, data residency. Can constrain services and regions; confirm
  current scope with AWS docs rather than memory.
- **Budget** — a monthly ceiling or "as cheap as possible". Pair with a cost estimate.
- **Team skills** — what the team already runs. A design the team cannot operate is the wrong design.

## Set the criticality tier deliberately

The tier is read by `aws-readiness` to scale the readiness review, so a prototype is not drowned in checks and a
critical workload is not under-reviewed.

| Tier | Meaning | Review depth signal for readiness review |
|---|---|---|
| `prototype` | Throwaway, demo, spike. Short-lived, no real users. | Minimal: basic cost guardrail and teardown. |
| `internal` | Internal tool, bounded blast radius, employees only. | Moderate: observability, backups, least-privilege. |
| `customer-facing` | External users, revenue or reputation at stake. | Full: alarms, runbooks, staged rollout, resilience. |
| `critical` | Outage is a business-level event; strict compliance. | Full plus multi-AZ/region, tested restore, threat model. |

When unsure between two tiers, pick the higher and say so.

## Produce candidate architectures, not a menu

- Give one to three candidates, never more. Each names its main services, what it optimizes for, and the
  trade-off (cost, operational load, time to build, scale ceiling, lock-in).
- Make exactly one recommendation and state why the closest alternative does not fit this workload's NFRs.
- Prefer the simplest design that meets the NFRs. Do not add managed services, regions, or redundancy the
  criticality tier does not call for.
- Defer every service-level choice to the domain router (see routing.md); record its recommendation here
  rather than re-deriving it.

## Ground moving facts in live docs

Service limits, pricing, regional availability, and newly launched features change. Confirm them with the
AWS MCP Server tools (`search_documentation`, `read_documentation`, `get_regional_availability`) before
stating a number that affects the choice. Flag any assumption you could not confirm.
