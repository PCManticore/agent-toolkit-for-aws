---
phase: deploy
status: draft
updated: <ISO date>
inputs: [verify-report.md, orr.md]
next: aws-maintain
---

> Next step: invoke the `aws-maintain` skill. It reads this file. If the user asked for a specific phase, invoke that phase's skill instead.

# Deploy record — <workload name>

- **Target environment:** <dev | staging | prod>
- **Target account / stack:** <account id or alias · stack/app name>
- **ORR gate:** <complete | blocked | absent (non-prod warning)>
  - Production requires a complete `orr.md`. A blocked or missing ORR blocks prod.
- **Artifact / version deployed:** <image digest, version, or commit>

## Change preview

How the diff was produced (`cloudformation` change set / `cdk diff` / `sam deploy` change set) and a
summary. Flag every replacement and deletion.

| Action | Resource | Note |
|---|---|---|
| create / modify / replace / delete | <logical id / ARN> | <why; data impact if replace/delete> |

## Rollout

- **Strategy:** <Lambda alias canary/linear · ECS blue/green · EC2 canary — via CodeDeploy>
- **Steps and bake:** <e.g. 10% for 10 min → 100%; alarms watched>
- **Alarms gating the rollout:** <alarm names>

## Rollback plan (written before deploy)

- **Trigger:** <which alarm or signal fires a rollback>
- **Steps:** <previous version/alias, change-set rollback, pipeline stop, redeploy last-good>
- **Data considerations:** <is any migration forward-only; is rollback safe>

## Confirmation

- **User confirmed mutating deploy:** <yes — who/when>

## Smoke check (post-deploy, read-only)

| Check | Result |
|---|---|
| <health endpoint / canary describe/invoke / key alarms> | <pass / fail → action> |

## Outcome

- **Status:** <deployed | rolled back | partial>
- **Follow-ups for maintain:** <anything aws-maintain should watch or re-run>
