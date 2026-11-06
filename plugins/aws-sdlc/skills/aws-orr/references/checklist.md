# ORR checklist

Each item has an ID (`ORR-<AREA>-<n>`), a question, how to check it (file evidence or a
**read-only** AWS check), what GREEN looks like, and the skill to route to if it is not GREEN.

## Scaling by criticality tier

Take the tier from `intent.md`. Run the items whose **Tier** is at or below the workload's tier.
A prototype runs roughly 8 core items; `critical` runs the full list.

| Tier | Meaning | Runs |
|---|---|---|
| prototype | throwaway / spike, no real users | `P` items only (~8) |
| internal | internal users, limited blast radius | `P` + `I` |
| customer-facing | external customers depend on it | `P` + `I` + `C` |
| critical | revenue / safety / compliance critical | all items (`P` `I` `C` `X`) |

Scoring: **GREEN** evidence shows it is met · **YELLOW** partial or planned (needs owner + date) ·
**RED** not met, no evidence (any RED → `orr.md` `status: blocked`).

## Ownership & on-call

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-OWN-1 | P | Is there a named owning team? | `intent.md` / repo CODEOWNERS | Team named with a contact | — (ask the user) |
| ORR-OWN-2 | I | Is there an on-call rotation reachable 24/7 for its SLA? | On-call doc / schedule link | Rotation exists and is linked | — |

## Observability

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-OBS-1 | P | Are logs captured for every component? | `aws logs describe-log-groups` | A log group per component, non-empty retention set | `aws-observability` |
| ORR-OBS-2 | I | Are the customer-impacting metrics emitted? | `aws cloudwatch list-metrics` | Latency, error rate, saturation present | `aws-observability`, `setting-up-cloudwatch-observability` |
| ORR-OBS-3 | C | Is there a dashboard showing service health at a glance? | `aws cloudwatch list-dashboards` | A dashboard with the key metrics | `setting-up-cloudwatch-observability` |
| ORR-OBS-4 | C | Are traces enabled across service boundaries? | `aws xray get-sampling-rules` / build.md | Tracing on for entry points and downstreams | `aws-observability` |

## Alarming

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-ALM-1 | P | Is there an alarm on each customer-impacting metric? | `aws cloudwatch describe-alarms` | Alarms on error rate and latency with thresholds | `setting-up-cloudwatch-alarm-notifications` |
| ORR-ALM-2 | I | Do alarms have an action (notify a human)? | `describe-alarms` → `AlarmActions` | Each alarm targets an SNS topic with a subscriber | `setting-up-cloudwatch-alarm-notifications` |
| ORR-ALM-3 | C | Have the alarms been tested (fired at least once)? | Alarm history / incident record | Evidence an alarm fired and paged | `setting-up-cloudwatch-alarm-notifications` |

## Runbooks

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-RBK-1 | I | Does each alarm have a runbook? | Repo `runbooks/` or wiki links | One runbook per alarm with triage steps | `aws-observability` |
| ORR-RBK-2 | C | Do runbooks name the rollback trigger and steps? | Runbook content | Rollback path documented and current | `aws-deploy` (deploy phase) |

## Deployment safety

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-DEP-1 | P | Are there separate environments (dev/staging/prod)? | `build.md` / account layout | Prod isolated from dev, ideally separate accounts | `aws-deploy` (deploy phase) |
| ORR-DEP-2 | I | Is the deploy staged (canary/linear), not all-at-once? | Pipeline / `deploy-record.md` | Traffic shifted gradually with bake time | `aws-deployment` |
| ORR-DEP-3 | C | Is automatic rollback wired to an alarm? | CodeDeploy config / pipeline | Rollback on alarm configured and tested | `aws-deployment` |

## Resilience

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-RES-1 | I | Is the workload multi-AZ where it matters? | `describe` on compute/DB | Stateful tiers span ≥2 AZs | `resilience-hub-getting-started` |
| ORR-RES-2 | I | Are backups taken and a restore tested? | Backup config + a restore record | Backups on, restore proven at least once | `resilience-hub-getting-started` |
| ORR-RES-3 | C | Are timeouts, retries with backoff, and idempotency set on downstream calls? | Code / `verify-report.md` | Bounded timeouts + jittered backoff | `resilience-hub-failure-mode-assessment` |
| ORR-RES-4 | C | Is there headroom under service quotas at peak? | `aws service-quotas list-service-quotas` | Usage well under limits with alarms | `aws-observability` |
| ORR-RES-5 | X | Has a failure been injected and survived? | FIS experiment record | A fault experiment ran and the workload held | `aws-fault-injection-service` |

## Security

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-SEC-1 | P | Are IAM roles least-privilege (no wildcard admin)? | `verify-report.md` / `aws iam list-roles` | Scoped actions and resources, no `*:*` | `aws-iam` |
| ORR-SEC-2 | I | Is data encrypted at rest and in transit? | `describe` on stores; TLS on endpoints | KMS at rest, TLS in transit | `aws-security` |
| ORR-SEC-3 | I | Are secrets in Secrets Manager, not in code or env plaintext? | Repo scan / `aws secretsmanager list-secrets` | No hardcoded secrets; references only | `aws-security` |
| ORR-SEC-4 | C | Is CloudTrail on, ideally multi-region? | `aws cloudtrail describe-trails` | A multi-region trail logging management events | `setting-up-cloudtrail-multi-region` |
| ORR-SEC-5 | X | Is there a current threat model? | Threat model doc / link | Threats enumerated with mitigations | `aws-security` |

## Dependencies

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-DEPEND-1 | I | Are all runtime dependencies known and listed? | `build.md` / dependency manifest | Dependencies enumerated with owners | `analyzing-release-readiness` (aws-agents-for-devsecops) |
| ORR-DEPEND-2 | C | Is degradation behaviour defined when a dependency fails? | Design / code | Fallback or fail-fast defined per dependency | `resilience-hub-failure-mode-assessment` |

## Load / scale testing

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-LOAD-1 | C | Has the workload been load-tested to expected peak? | Load test report | Peak load sustained within SLOs | `analyzing-release-readiness` (aws-agents-for-devsecops) |
| ORR-LOAD-2 | X | Is autoscaling proven under the test? | Scaling config + test result | Scaling triggered and settled under load | `aws-observability` |

## Cost guardrails

| ID | Tier | Question | How to check | GREEN | Route if not GREEN |
|---|---|---|---|---|---|
| ORR-COST-1 | P | Is there a budget with an alert? | `aws budgets describe-budgets` | A budget with an alert threshold | `aws-billing-and-cost-management` |
| ORR-COST-2 | I | Are resources tagged for cost allocation? | `aws resourcegroupstaggingapi get-resources` | Consistent cost-allocation tags | `aws-billing-and-cost-management` |

Prototype core set (`P`): ORR-OWN-1, OBS-1, ALM-1, DEP-1, SEC-1, COST-1 plus any obvious RED
risk the agent spots — about eight items, not sixty.
