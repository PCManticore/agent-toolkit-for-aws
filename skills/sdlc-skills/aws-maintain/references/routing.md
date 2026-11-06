# aws-maintain routing

Signal in the request maps to the existing skill that owns the depth. All names below were verified
to exist in this repo. Plugin is noted when the skill is not in aws-core.

## Loop 1 - Incident / triage

| Signal | Route to | Plugin | Why |
|---|---|---|---|
| Alarm, error spike, failed request, trace a request across services, count/break down failures | **aws-investigation** | aws-core | Answers "what is happening" from evidence already in the account (deployed artifacts, per-service logs, query results). Evidence-first by design. |
| Application returning errors or 5xx, broken behavior to isolate | **troubleshooting-application-failures** | specialized (operations-skills) | Structured procedure for narrowing an application failure to its failing component. |
| Lambda function timing out | **debugging-lambda-timeouts** | specialized (serverless-skills) | Steps through config, CloudWatch logs/metrics, VPC, cold starts, memory, and downstream calls for a timeout. |
| You want an agent to drive the incident investigation end to end | **investigating-incidents-with-aws-devops-agent** | aws-agents-for-devsecops | The AWS DevOps Agent runs the incident investigation workflow. |
| Reading metrics, logs, or traces to find the signal | **aws-observability** | aws-core | Owns CloudWatch metrics/logs, X-Ray/Application Signals, and how to query them. |

## Loop 2 - Health / observability gaps

| Signal | Route to | Plugin | Why |
|---|---|---|---|
| Customer-impacting metric has no alarm, or an alarm has no action | **setting-up-cloudwatch-alarm-notifications** | specialized (operations-skills) | Wires alarms to SNS/notification actions so a breach reaches someone. |
| No dashboards, no tracing, general observability setup | **setting-up-cloudwatch-observability** | specialized (operations-skills) | Stands up metrics, dashboards, and tracing for a workload. |
| Deciding what to measure and how to read it | **aws-observability** | aws-core | The domain router for observability choices. |

## Loop 3 - Cost / efficiency

| Signal | Route to | Plugin | Why |
|---|---|---|---|
| Bill went up, over budget, idle or oversized resources, tagging, right-sizing, budgets and alerts | **aws-billing-and-cost-management** | aws-core | Owns cost analysis, budgets, cost allocation tags, and efficiency recommendations. |

## Loop 4 - Security posture & upgrades/deprecations

| Signal | Route to | Plugin | Why |
|---|---|---|---|
| Security posture, encryption, public exposure, CVE, threat model drift | **aws-security** | aws-core | Domain router for security review of a live workload. |
| IAM role or policy wider than least-privilege | **aws-iam** | aws-core | Owns IAM policy review and least-privilege scoping. |
| Runtime EOL, database or engine version upgrade, deprecated feature | the owning domain/service skill (for example **aws-serverless** for Lambda runtimes, **aws-database** for engine versions) | aws-core | The service skill carries supported versions and the upgrade path; confirm EOL dates and replacements in live AWS docs. |
| Web Function errors, latency, concurrency per environment, cross-request state leaks | **aws-lambda-web-functions** (loaded from the AWS MCP Server with `aws___retrieve_skill` when not installed) | Its `references/troubleshooting.md`, `scaling-and-concurrency.md` and `observability.md` cover the Web Functions model. |
| Stuck, failed or repeated durable executions, replay or idempotency problems | **aws-lambda-durable-functions** (loaded from the AWS MCP Server with `aws___retrieve_skill` when not installed) | Its troubleshooting guidance covers execution history, checkpoints, waits and duplicate side effects. |

## Readiness drift (any loop)

| Signal | Route to | Plugin | Why |
|---|---|---|---|
| Periodic review, or a major change landed | **aws-readiness** | aws-sdlc | Re-run the Operational Readiness Review and diff against the last `readiness.md`; new RED/YELLOW items become maintain findings. |

## Phase hand-off (not a skill lookup)

- Fix changes architecture -> **aws-intent**.
- Code or config fix -> **aws-build** -> **aws-verify** -> **aws-deploy**.
