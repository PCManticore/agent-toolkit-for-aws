# aws-build best practices

Build-phase slice of the Well-Architected pillars. Concise and opinionated;
confirm limits and pricing against live AWS docs when precision matters.

## Infrastructure as code

- Keep every resource in IaC from the first commit. No click-ops that IaC does
  not know about — it causes drift the verify and ORR phases cannot see.
- Synthesize after every change. A stack that has not synthesized since its last
  edit is not buildable; treat a failed synth as a stop-the-line event.
- Build in small, coherent increments (one component or one wiring per change),
  not one large unsynthesized template.
- Pin tool and construct-library versions so a synth is reproducible.
- CloudFormation best practices:
  https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html
- CDK best practices:
  https://docs.aws.amazon.com/cdk/v2/guide/best-practices.html

## Security (build it in, don't bolt it on)

- Least-privilege IAM per role: only the actions and resources the role uses, no
  `*` resource on a principal you control, no admin-equivalent roles.
- No secrets in code, templates, or environment literals. Store in Secrets
  Manager or SSM SecureString; reference by ARN; enable rotation.
- Encrypt at rest and in transit by default: KMS on data stores, TLS on
  endpoints.
- No hardcoded account IDs, ARNs, or region strings — pass by reference or
  parameter.
- IAM security best practices:
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Secrets Manager best practices:
  https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html

## Reliability

- Set timeouts, retries with backoff, and dead-letter targets on async paths as
  you build them, not after.
- Prefer managed, multi-AZ defaults; record single-AZ choices as a deliberate
  trade-off in build.md.

## Cost

- Right-size at build time (memory, instance class, capacity mode) against the
  intent budget; note the assumption in build.md so verify can check it.
- Tag resources for cost allocation from the start.

## Operability

- Emit structured logs and the metrics the maintain phase will alarm on; wire
  tracing where the path crosses services.
- Name the synth/validate command exactly in build.md so verify runs the same
  one.

## What to hand to aws-verify

build.md must let verify reproduce the build without guessing: the IaC tool, the
exact synth command, the full resource list, the language and test command for
app code, and any NFR assumption (budget, scale) that verify should check.
