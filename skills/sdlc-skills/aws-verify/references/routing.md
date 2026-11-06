# aws-verify routing

Rung → existing skill. Every skill below was verified to exist in this repo.
Core skills ship with the **aws-core** plugin. Non-core skills name their plugin
or specialized category.

## Static analysis

| Signal | Route to | Why |
|---|---|---|
| CDK app | **aws-cdk** | `cdk synth` renders the template; cdk-nag rule packs catch common issues before deploy. |
| CloudFormation / SAM template | **aws-cloudformation** | `cfn-lint` for schema and best-practice linting; `cfn-guard` for policy-as-code rules; `sam validate --lint` for SAM. |
| IAM policies | **aws-iam** | IAM Access Analyzer policy validation; find `*` resources and over-broad actions. |

## Security scan

| Signal | Route to | Plugin / notes |
|---|---|---|
| Full security scan of the stack/app | **scanning-with-aws-security-agent** | aws-agents-for-devsecops plugin. |
| Scan only the change / diff | **diff-scanning-with-aws-security-agent** | aws-agents-for-devsecops plugin. |
| Neither agent installed | local scanners | cfn-guard rule packs, cdk-nag; record the tool used. |

## Tests

| Signal | Route to | Plugin / notes |
|---|---|---|
| Serverless local invoke, handler behavior | **aws-serverless** | Owns `sam local invoke` and serverless test guidance. |
| Integration / release-readiness tests against a dev stack | **running-release-tests** | aws-agents-for-devsecops plugin. Pair with **analyzing-release-readiness** for a readiness verdict. |

Unit tests use the build's own test command (from build.md); no AWS skill needed.

## Cost

| Signal | Route to | Why |
|---|---|---|
| Monthly cost estimate vs the intent budget | **aws-billing-and-cost-management** | Estimate from the resource list; compare to budget; flag overage. |

## Resilience

| Signal | Route to | Plugin / notes |
|---|---|---|
| Failure-mode assessment of the architecture | **resilience-hub-failure-mode-assessment** | specialized: resilience-skills. |
| Fault injection against a running stack | **aws-fault-injection-service** | specialized: resilience-skills. Mutates real resources — confirm first. |

## Optional review

| Signal | Route to | Why |
|---|---|---|
| Significant or customer-facing system | **aws-well-architected-review** | Pillar review across reliability, security, cost, performance, operations, sustainability. |

## Handoff

The verify report hands off to **aws-orr**, the production readiness gate and the
next phase in the aws-sdlc flow. aws-orr reads verify-report.md (plus intent.md
and build.md) and decides GREEN/YELLOW/RED readiness.

## Rule

If a routed skill is not installed, run the closest local check you can, mark the
rung PASS/FAIL/SKIPPED with that evidence, and name the skill that would go
deeper. Do not report a rung as PASS without running it.
