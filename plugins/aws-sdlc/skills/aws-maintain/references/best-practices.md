# aws-maintain best practices

The maintain phase lives mostly in the Well-Architected Operational Excellence pillar, with slices
of Security, Cost Optimization, and Reliability. Keep each practice tied to a loop.

## Operate (all loops)

- Treat operations as evidence-driven. Read metrics, logs, and traces before forming a cause, and
  keep a provenance note per claim.
- Default to read-only. A mutating change in a live account needs explicit user confirmation and a
  known rollback path (the one recorded in `deploy-record.md`).
- Make small, reversible changes. One change at a time, verified against the signal that triggered
  it.
- Ground limits, pricing, regional availability, EOL dates, and new-feature claims in live AWS
  docs, not memory.

## Loop 1 - Incident / triage

- Establish impact first: scope, start time, customer effect. Then cause, then fix.
- Use the account's own records - deployed artifact, per-service logs, query results - not resource
  names or the newest stored version.
- Capture a timeline and the evidence in `maintain-log.md` so a follow-up or COE has the trail.
- Docs: https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/operational-excellence.html

## Loop 2 - Health / observability

- Alarm on customer-impacting metrics (latency, error rate, availability), not just host metrics,
  and make sure every alarm has an action.
- Cover the three signals: metrics, logs, traces. A dashboard per service and a top-level health
  view.
- Test that an alarm actually notifies someone before you rely on it.
- Docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

## Loop 3 - Cost / efficiency

- Read spend before acting: largest line items and their trend. Separate waste (idle, oversized,
  untagged) from structural cost.
- Set budgets with alerts; enforce cost allocation tags so spend maps to owners.
- Right-size and adopt commitment pricing (Savings Plans, Reserved) only for steady usage; quote
  the saving and the risk.
- Docs: https://docs.aws.amazon.com/cost-management/latest/userguide/what-is-costmanagement.html

## Loop 4 - Security posture & upgrades/deprecations

- Track runtime and engine EOL dates and plan upgrades before the date, not after.
- Keep IAM at least-privilege; re-review roles that have widened. Encryption at rest and in
  transit; secrets in Secrets Manager; CloudTrail on.
- Review public exposure (open security groups, public endpoints without WAF) as part of each
  posture pass.
- Docs: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html

## Readiness drift

- Re-run `aws-readiness` on a schedule and after major changes; a passing readiness review decays as the workload and
  its dependencies change.
- Scale the depth by criticality from `intent.md` - do not drown a prototype in full readiness review items.
