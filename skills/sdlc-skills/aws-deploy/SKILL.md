---
name: aws-deploy
description: Runs the deploy phase — environments, change set / diff preview, staged rollout, rollback plan, and CI/CD pipeline — after verify and ORR. Reads verify-report.md and orr.md; refuses a production deploy when orr.md is missing or blocked (non-prod deploys proceed with a warning). Previews every change and requires explicit user confirmation before any mutating call. Triggers: "deploy", "ship it", "release to prod", "roll out", "change set", "cut-over". Writes .aws-sdlc/deploy-record.md; next is aws-maintain. Not the CI/CD service skill — this is the phase; for CodePipeline/CodeBuild/CodeDeploy setup it routes to aws-deployment. Not for building (aws-build) or the readiness gate (aws-orr).
metadata:
  version: "1"
---

# AWS Deploy (phase)

Take a verified, readiness-reviewed workload to an environment safely: preview the change,
roll it out in stages, keep a written way back, and record what happened. This is the SDLC
**phase** skill. The CI/CD **service** skill is `aws-deployment` (CodePipeline/CodeBuild/CodeDeploy);
this skill routes pipeline work there.

**Works best with** the aws-core plugin installed (domain skills) and the
[AWS MCP server](https://docs.aws.amazon.com/aws-mcp/) for previews and CLI execution.
All guidance also works with standard AWS CLI access.

## When to use

- Deploying a workload to dev, staging, or production.
- Setting up or changing the rollout strategy or the pipeline that deploys it.
- Standalone: if `verify-report.md` or `orr.md` are missing, ask for the target environment and
  confirm readiness instead of refusing — but hold the production gate below.

## When not to use

- Writing IaC or app code — use `aws-build`.
- The readiness gate itself — use `aws-orr`.
- Deep CodePipeline/CodeBuild/CodeDeploy configuration — route to `aws-deployment`.

## Workflow

1. **Read inputs and set the target.** Load `.aws-sdlc/verify-report.md` and `.aws-sdlc/orr.md`.
   Confirm the target environment (dev / staging / prod). *Exit:* environment is fixed.
2. **Gate on readiness (production only).** If target is prod and `orr.md` is missing or
   `status: blocked`, **refuse** and point at `aws-orr` to close the RED items. Non-prod deploys
   proceed with a warning when the ORR is absent. *Exit:* prod is allowed only with a complete ORR.
3. **Confirm environment isolation.** Prefer separate AWS accounts per environment; at minimum a
   separate stack and state. Never deploy to prod from the same account state as dev by accident.
   *Exit:* the target account/stack is named and confirmed.
4. **Preview the change.** Produce a diff or change set and show it: `cloudformation` change set,
   `cdk diff`, or `sam deploy` with change-set confirmation. Summarise what is created, modified,
   replaced, or deleted — call out any replacement or deletion. *Exit:* the user has seen the diff.
5. **Write the rollback plan before deploying.** Record the trigger (which alarm or signal), the
   steps (previous version/alias, change-set rollback, or pipeline stop), and the data considerations.
   *Exit:* rollback plan is written in `deploy-record.md`.
6. **Confirm, then apply in stages.** Get explicit user confirmation before the first mutating call.
   Roll out gradually by compute type (see Routing): Lambda alias canary/linear via CodeDeploy, ECS
   blue/green, EC2/on-prem canary via CodeDeploy. Bake and watch alarms between steps. *Exit:* traffic
   shifted to the new version with no alarm breach.
7. **Smoke check.** Run a read-only post-deploy check (health endpoint, a `describe`/`invoke` of a
   canary path, key alarms still OK). If it fails, execute the rollback plan. *Exit:* smoke check passes.
8. **Record and hand off.** Write `.aws-sdlc/deploy-record.md`. `next: aws-maintain`. *Exit:* record written.

## Routing

Full table with reasons: [references/routing.md](references/routing.md).

| Signal | Route to | Plugin |
|---|---|---|
| Build or change the CI/CD pipeline (CodePipeline/CodeBuild/CodeDeploy, buildspec) | `aws-deployment` | aws-core |
| CDK app: `cdk diff` / `cdk deploy` | `aws-cdk` | aws-core |
| Raw CloudFormation change sets | `aws-cloudformation` | aws-core |
| SAM / serverless deploy and Lambda alias shifting | `aws-serverless` | aws-core |
| ECS service deploy config (blue/green, circuit breaker) | `aws-containers` | aws-core |
| Deploy role is over-broad | `aws-iam` | aws-core |
| Post-deploy alarms / dashboards to watch | `aws-observability` | aws-core |
| Readiness is blocked or missing | `aws-orr` | aws-sdlc |

## Artifact

Writes `.aws-sdlc/deploy-record.md` from
[assets/deploy-record-template.md](assets/deploy-record-template.md). `next: aws-maintain`.

## Rules

- **Gate production on the ORR.** No prod deploy while `orr.md` is missing or blocked. Non-prod is
  allowed with an explicit warning.
- **Preview before you apply.** Always show a diff or change set first; never apply blind.
- **Confirm every mutation.** Get explicit user go-ahead before the first mutating AWS call, and
  before any step that replaces or deletes a resource.
- **Rollback plan is written before the deploy, not after.**
- **Recommend, don't mandate.** Offer rollout options with trade-offs and one recommendation with a
  reason; let compute type and pipeline choice defer to the domain skills.
- **Route, don't duplicate.** Pipeline, CDK, CFN, SAM, and ECS specifics live in their skills.
- **Ground facts in live sources.** Confirm deploy limits, traffic-shift options, and regional
  availability via the AWS MCP Server (`search_documentation`, `read_documentation`,
  `get_regional_availability`), not training data.
- **Degrade gracefully.** If a routed skill is not installed, still give the deploy answer and name
  the skill that would go deeper.
