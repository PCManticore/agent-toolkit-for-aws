---
phase: build
status: draft
updated: <ISO date>
inputs: [intent.md]
next: aws-verify
---

# Build record

## Summary

One or two sentences: what was built and for which intent.

## IaC tool

- **Chosen:** CDK | CloudFormation | SAM | AWS Blocks
- **Why:** one reason tied to the intent (team language, declarative estate,
  local-invoke loop, paved pattern).
- **Runner-up:** the next-best option and why it lost.
- **Synth/validate command:** the exact command, e.g. `cdk synth`,
  `sam validate --lint`, `cfn-lint template.yaml`.

## Resources built

| Resource | Service | Purpose | Notes (encryption, multi-AZ, capacity) |
|---|---|---|---|
| | | | |

## Application code

- **Language / runtime:**
- **Build command:**
- **Test command:**
- **Entry points:** handlers or services and what triggers them.

## Security wiring

- **IAM:** roles created and the least-privilege scope of each (no `*` resource).
- **Secrets:** what is stored in Secrets Manager / SSM and referenced by ARN.
- **Encryption:** at rest (KMS keys) and in transit (TLS/ACM).

## NFR assumptions to verify

- **Budget:** stated budget from intent and the cost assumption built against it.
- **Scale / latency:** the target and how the build is sized for it.

## Open items / deviations from intent

- Anything built differently from the intent architecture, with the reason.

## Next

Run **aws-verify** against this record.
