# readiness review routing

When an item is YELLOW or RED, route the fix to the skill that owns the domain. readiness review does not
re-derive these — it points at them. Skill names below are verified to exist in this repo.
Note the plugin for any skill outside aws-core.

| Signal (from the item) | Route to | Plugin | Why |
|---|---|---|---|
| No alarm, or alarm has no notification action | `setting-up-cloudwatch-alarm-notifications` | specialized (operations-skills) | Owns SNS topics, subscriptions, and wiring alarm actions |
| Missing metrics, logs, traces, or a health dashboard | `aws-observability` | aws-core | Owns the metrics/logs/traces strategy and dashboards |
| CloudWatch agent / Application Signals / dashboard setup | `setting-up-cloudwatch-observability` | specialized (operations-skills) | Step-by-step CloudWatch observability setup |
| No audit trail, or single-region trail only | `setting-up-cloudtrail-multi-region` | specialized (operations-skills) | Owns multi-region CloudTrail setup |
| No multi-AZ, no backups, untested restore | `resilience-hub-getting-started` | specialized (resilience-skills) | Entry point for resilience assessment and policy |
| Undefined failure/degradation behaviour, missing timeouts/retries | `resilience-hub-failure-mode-assessment` | specialized (resilience-skills) | Owns failure-mode analysis |
| Resilience across many accounts | `resilience-hub-multi-account` | specialized (resilience-skills) | Multi-account resilience assessment |
| No fault injection evidence | `aws-fault-injection-service` | specialized (resilience-skills) | Owns FIS experiments that prove resilience |
| Encryption, secrets, posture, threat model gaps | `aws-security` | aws-core | Owns security controls and threat modelling |
| Over-broad or wildcard IAM | `aws-iam` | aws-core | Owns least-privilege policy design |
| No budget or cost alerts, missing cost tags | `aws-billing-and-cost-management` | aws-core | Owns budgets, alerts, and cost allocation |
| Release tests / readiness analysis gap | `analyzing-release-readiness` | aws-agents-for-devsecops | Analyzes release-test results for go/no-go |
| The review should widen to all Well-Architected pillars | `aws-well-architected-review` | aws-core | Full six-pillar review beyond the ops gate |

If a routed skill is not installed, still record the finding and the owner, and name the skill so
a later run can go deeper. Deployment-safety fixes (staged rollout, auto-rollback, change sets) are
owned by the deploy phase: record them here but hand the work to `aws-deploy`, which routes pipeline
setup to `aws-deployment`.
