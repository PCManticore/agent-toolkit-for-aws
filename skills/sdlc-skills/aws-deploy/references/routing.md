# Deploy routing

The deploy phase owns the workflow — environments, preview, staged rollout, rollback, smoke check —
and routes the mechanics to the domain skills. Skill names below are verified to exist in this repo.

## Pipeline vs phase (the name clash)

`aws-deploy` (this skill) is the SDLC **phase**. `aws-deployment` is the **service** skill for
CodePipeline, CodeBuild, CodeDeploy, CodeConnections, and CodeArtifact. When the user wants a
pipeline built or changed, route to `aws-deployment`; keep the phase workflow (gate, preview,
rollout, rollback, record) here.

| Signal | Route to | Plugin | Why |
|---|---|---|---|
| Build/change CI/CD pipeline, buildspec, CodeDeploy strategy config | `aws-deployment` | aws-core | Owns CodePipeline/CodeBuild/CodeDeploy/CodeConnections/CodeArtifact |
| CDK app deploy — `cdk diff`, `cdk deploy`, CDK Pipelines | `aws-cdk` | aws-core | Owns CDK synth/diff/deploy |
| Raw CloudFormation stacks and change sets | `aws-cloudformation` | aws-core | Owns template authoring and change-set review |
| SAM / serverless deploy, Lambda alias + version traffic shifting | `aws-serverless` | aws-core | Owns serverless packaging and Lambda deploy |
| Lambda Web Functions revision, endpoint traffic, `aws lambda-web` deploy | `aws-lambda-web-functions` | specialized (loaded from the AWS MCP Server with `aws___retrieve_skill` when not installed) | Revisions and endpoints are the deploy unit; read its `references/deployment.md`. |
| Durable function versions while executions are in flight | `aws-lambda-durable-functions` | specialized (loaded from the AWS MCP Server with `aws___retrieve_skill` when not installed) | In-flight executions replay against the version they started on; read its deployment guidance before shifting traffic. |
| ECS service deploy (blue/green, deployment circuit breaker, rolling params) | `aws-containers` | aws-core | Owns ECS/Fargate service deployment config |
| Deploy/execution role too broad | `aws-iam` | aws-core | Owns least-privilege policy for the deploy role |
| Alarms and dashboards to watch during and after rollout | `aws-observability` | aws-core | Owns the metrics/alarms that gate a canary |
| Readiness missing or blocked before a prod deploy | `aws-orr` | aws-sdlc | The readiness gate this phase depends on |

## Rollout strategy by compute type

Pick the staged-rollout mechanism from what runs the workload; `aws-deployment` owns the CodeDeploy
configuration that implements it.

| Compute | Mechanism | Notes |
|---|---|---|
| Lambda | CodeDeploy traffic shifting on an alias (canary or linear) | Alarm-gated; auto-rollback on alarm |
| ECS / Fargate | CodeDeploy blue/green (or ECS native rolling with circuit breaker) | Shift at the load balancer; keep the old task set until bake passes |
| EC2 / on-prem | CodeDeploy in-place or blue/green with a canary fleet | Idempotent lifecycle hooks; watch health checks |

If a routed skill is not installed, still give the phase answer — the preview, the rollout shape, the
rollback plan — and name the skill that would implement the mechanics.
