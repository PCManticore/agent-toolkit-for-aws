# readiness review best practices

The readiness review covers the Well-Architected **Operational Excellence** and **Reliability** slice that must
hold before production traffic. Keep it concise; defer depth to the routed skills.

## Operational Excellence

- **Observe before you alarm.** You cannot alarm on a metric you do not emit. Confirm metrics, logs,
  and traces exist, then put alarms on the customer-impacting ones.
  https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html
- **Every alarm pages a human with a runbook.** An alarm with no action and no runbook is noise.
  Test that alarms actually fire. https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html
- **Make deploys reversible.** Stage rollout (canary or linear) and wire automatic rollback to an
  alarm so a bad deploy backs out without a human in the loop.
  https://docs.aws.amazon.com/wellarchitected/latest/operational-readiness-reviews/wa-operational-readiness-reviews.html

## Reliability

- **Design for failure.** Multi-AZ for stateful tiers; bounded timeouts, retries with exponential
  backoff and jitter, and idempotency on downstream calls.
  https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html
- **Prove recovery, don't assume it.** A backup you have never restored is a hope. Test a restore and
  keep headroom under service quotas, with alarms before you hit them.
  https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/plan-for-disaster-recovery-dr.html
- **Inject faults for critical workloads.** Confirm the workload survives the failures you designed
  for, rather than discovering it in an incident.
  https://docs.aws.amazon.com/fis/latest/userguide/what-is.html

## Security and cost as readiness gates

- **Least privilege, encryption, secrets, audit.** No wildcard admin roles; KMS at rest and TLS in
  transit; secrets in Secrets Manager; CloudTrail on (multi-region for anything customer-facing).
  https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
- **A budget with an alert is the minimum cost guardrail.** Add cost-allocation tags so spend is
  attributable. https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html

## Running the review

- **Scale to the workload.** A prototype gets the ~8 core items; a critical workload gets the full
  list. Drowning a spike in 60 items trains people to ignore the readiness review.
- **Score with evidence.** GREEN needs a file or a read-only `describe`/`list` behind it. YELLOW is a
  real gap with an owner and a date, not a shrug. Any RED blocks the production deploy.
- **Ground changing facts in live docs.** Quotas, limits, regional availability, and new features
  change — confirm them through the AWS MCP Server, not memory.
- **Re-run on drift.** Readiness decays. `aws-maintain` re-runs this skill and diffs against the last
  `readiness.md` to catch regressions.
