# aws-verify best practices

Verify-phase slice of the Well-Architected pillars. The phase is evidence, not
opinion: a check counts only when it ran and produced output you recorded.

## The ladder, cheapest first

Run static checks before tests, and tests before anything that touches a live
account. A failure caught by `cdk synth` or `cfn-lint` costs seconds; the same
fault caught by a failed dev deploy costs minutes and real resources. Climb:
static → security → tests → cost → resilience.

## Evidence discipline

- Record the exact command and a short summary of its output for every rung.
- Three states only: PASS (ran, clean), FAIL (ran, found a blocking issue),
  SKIPPED (could not run — say why). A rung you did not run is never PASS.
- Keep the report reproducible: another agent should be able to re-run each
  command from the report alone.

## Static analysis

- Synthesize the full stack; a template that will not synth cannot be verified.
- Lint with cfn-lint and enforce guardrails with cfn-guard / cdk-nag rule packs.
- cfn-lint: https://github.com/aws-cloudformation/cfn-lint
- cfn-guard: https://docs.aws.amazon.com/cfn-guard/latest/ug/what-is-guard.html

## IAM least-privilege

- Validate every policy with IAM Access Analyzer; treat findings as blocking
  until justified.
- Flag `*` resources, `iam:PassRole` without a condition, and wildcard actions.
- Access Analyzer policy validation:
  https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-policy-validation.html

## Security scan

- Scan the whole stack on first verify; diff-scan on iterations to stay fast.
- Resolve high and critical findings before handing off; record accepted risks
  with an owner.

## Tests

- Unit tests gate logic; local invoke gates handler wiring; integration tests on
  a dev stack gate the real service contract.
- Never run integration tests against production. Confirm before deploying a dev
  stack.

## Cost

- Estimate monthly cost from the built resources and compare to the intent
  budget. An over-budget estimate is a FAIL, not a footnote.
- AWS Pricing Calculator: https://calculator.aws/

## Resilience

- Identify single points of failure, missing backups, and absent
  timeouts/retries before production.
- Inject faults only against a non-prod stack, with confirmation.
- Resilience Hub:
  https://docs.aws.amazon.com/resilience-hub/latest/userguide/what-is.html
- Fault Injection Service:
  https://docs.aws.amazon.com/fis/latest/userguide/what-is.html

## Scale depth to criticality

Read the criticality from intent.md (prototype / internal / customer-facing /
critical). A prototype needs synth, unit tests, and a cost sanity check. A
critical system needs the full ladder including resilience and a
Well-Architected review. Do not drown a prototype in checks it does not need,
and do not ship a critical system on a prototype's ladder.

## What to hand to aws-orr

verify-report.md must give the readiness gate what it needs: each rung's verdict
and evidence, any blocking FAILs, the cost estimate vs budget, and the resilience
findings. aws-orr turns these into GREEN/YELLOW/RED items.
