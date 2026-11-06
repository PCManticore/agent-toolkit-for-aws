---
name: aws-verify
description: >-
  Verify phase of the AWS SDLC lifecycle: run a pre-ship verification ladder
  over what aws-build produced. Triggers: "verify", "is this ready to ship",
  "lint/synth the stack", "check my IAM", "run the tests", "security scan",
  "will this cost too much". Runs static checks (cdk synth, cfn-lint, cfn-guard,
  IAM policy validation), security scans, unit / local-invoke / integration
  tests, a cost estimate against the intent budget, and resilience checks, each
  reported PASS / FAIL / SKIPPED with evidence. Reads .aws-sdlc/build.md, writes
  .aws-sdlc/verify-report.md, hands off to aws-orr. Not for building code (use
  aws-build) or the production readiness gate (use aws-orr).
metadata:
  version: "1"
---

# AWS Verify

## Overview

The verify phase checks that a build is ready to ship, before any production
readiness gate. It runs a verification ladder from cheapest to most involved —
static analysis, security scan, tests, cost, resilience — and records each check
as PASS, FAIL, or SKIPPED with the command run and a summary of its output. It
routes the actual checking to the skills and tools that own each rung; it does
not reimplement linters or scanners.

Works best with the aws-core plugin installed (domain skills) and the AWS MCP
Server for grounding limits, pricing, and regional availability in live docs.

## When to use

- A build exists (from `aws-build` or already present) and you need evidence it
  is safe to move toward deployment.
- You want a repeatable PASS/FAIL report, not a one-off "looks fine".

## When not to use

- Writing or fixing the IaC and app code → **aws-build**.
- The production readiness gate (ownership, on-call, alarms, runbooks) →
  **aws-orr**.

## Workflow

If `.aws-sdlc/build.md` is missing, do not refuse: infer the IaC tool and synth
command from the project (look for `cdk.json`, `template.yaml`, `samconfig`),
ask at most 1–3 questions, then run the ladder on what is there.

Climb the ladder in order. A rung that cannot run (tool or stack absent) is
SKIPPED with the reason — never silently dropped. Record every rung.

1. **Static — IaC synthesizes and lints.** `cdk synth` for CDK;
   `cfn-lint` then `cfn-guard` for CloudFormation/SAM templates; `sam validate
   --lint` for SAM. Route to **aws-cdk** / **aws-cloudformation**. Exit: synth
   succeeds and lint is clean or every finding is triaged.
2. **Static — IAM least-privilege.** Run IAM Access Analyzer policy validation
   on every policy; flag `*` resources and over-broad actions. Route to
   **aws-iam**. Exit: no unjustified wildcards; each exception noted.
3. **Security — scan.** Scan with the AWS Security Agent
   (**scanning-with-aws-security-agent**), or diff-scan the change with
   **diff-scanning-with-aws-security-agent** (both: aws-agents-for-devsecops
   plugin). If neither is installed, run a local scanner (e.g. cfn-guard rule
   packs, cdk-nag) and say so. Exit: no unresolved high/critical findings.
4. **Tests — unit.** Run the app's unit suite with the build's test command.
   Exit: suite passes; record counts.
5. **Tests — local invoke.** For serverless, `sam local invoke` against sample
   events. Route to **aws-serverless**. Exit: handlers return expected output
   locally.
6. **Tests — integration against a dev stack.** Deploy to a non-prod/dev stack
   and run integration tests against it; for release-style suites route to
   **running-release-tests** (aws-agents-for-devsecops). Confirm with the user
   before any deploy. Exit: integration tests pass on the dev stack.
7. **Cost — estimate vs budget.** Estimate monthly cost for the built resources
   and compare to the intent budget. Route to
   **aws-billing-and-cost-management**. Exit: estimate is at or under budget, or
   the overage is flagged.
8. **Resilience — failure modes.** Assess failure modes with
   **resilience-hub-failure-mode-assessment** and, where a running stack allows,
   inject faults with **aws-fault-injection-service** (both: resilience-skills).
   Exit: single points of failure identified; mitigations noted.
9. **Optional — architecture review.** For significant or customer-facing
   systems, run **aws-well-architected-review**. Exit: review findings recorded.
10. **Record and hand off.** Write `.aws-sdlc/verify-report.md` from the
    template: every rung with PASS/FAIL/SKIPPED, the command, and an output
    summary. Any FAIL on a required rung → `status: blocked`. Exit: report
    exists with `next: aws-orr`.

## Routing

Full table with reasons in [references/routing.md](references/routing.md).

| Rung | Route to |
|---|---|
| Synth / lint / guard | aws-cdk, aws-cloudformation |
| IAM validation | aws-iam |
| Security scan | scanning-with-aws-security-agent, diff-scanning-with-aws-security-agent (devsecops) |
| Local invoke / serverless tests | aws-serverless |
| Integration / release tests | running-release-tests (devsecops) |
| Cost estimate | aws-billing-and-cost-management |
| Resilience | resilience-hub-failure-mode-assessment, aws-fault-injection-service (resilience) |
| Architecture review | aws-well-architected-review |

## Artifact

Write [.aws-sdlc/verify-report.md](assets/verify-report-template.md) using the
bundled template. It feeds **aws-orr** (the production readiness gate).

## Rules

- **Every rung is PASS, FAIL, or SKIPPED with evidence** (the command and an
  output summary). No rung is dropped silently; "could not run" is SKIPPED with
  a reason.
- **Recommend, don't mandate.** Where a check has options (which scanner, which
  test depth), name one with a reason and defer depth to the routed skill.
- **Route, don't duplicate.** Use the owning skill or tool for each rung.
- **Ground facts in live docs.** Pricing, limits, and regional availability come
  from the AWS MCP Server tools, not training data.
- **No mutating AWS calls without explicit user confirmation.** Deploying a dev
  stack and injecting faults change real resources — confirm first.
- **If a routed skill isn't installed,** run the closest local check, mark the
  rung, and name the skill that would go deeper.
- **Scale depth to criticality** from intent.md: a prototype needs synth, unit
  tests, and a cost sanity check; a critical system needs the full ladder.
- **A FAIL on a required rung blocks the report** so aws-orr and aws-deploy see
  the gate.
