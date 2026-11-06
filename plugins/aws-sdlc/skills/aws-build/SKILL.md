---
name: aws-build
description: >-
  Use whenever you write infrastructure-as-code or application code for an AWS workload, including "run the
  build phase", "build it", "implement the intent", "write the CDK/CloudFormation/SAM", "scaffold the app",
  or any time .aws-sdlc/intent.md exists and code is next. Build phase: picks an IaC tool by context (CDK,
  CloudFormation, SAM, AWS Blocks) and routes to its skill, wires least-privilege IAM and secrets, adds unit
  tests, and builds in increments that synth. Writes .aws-sdlc/build.md. Not for choosing the architecture
  (aws-intent), pre-ship checks (aws-verify) or deploying (aws-deploy).
metadata:
  version: "1"
---

# AWS Build

## Overview

The build phase turns an intent into code: infrastructure-as-code plus the
application that runs on it. This skill runs the build workflow and routes the
real work to the domain and service skills that own each decision. It does not
reimplement CDK, CloudFormation, SDK, or service guidance — it sequences them
and keeps the build honest (small increments, each one synthesizes cleanly,
least-privilege from the start).

Works best with the aws-core plugin installed (domain skills) and the AWS MCP
Server for grounding limits, pricing, and regional availability in live docs.

## When to use

- You have an architecture (from `aws-intent` or already decided) and need to
  build the IaC and app code.
- You are scaffolding a new stack, adding a resource, or wiring services.

## When not to use

- Choosing requirements or the architecture → **aws-intent**.
- Checking the build is ready to ship (synth/lint/scan/test/cost) → **aws-verify**.
- Rolling the build out to an environment → **aws-deploy**.

## Workflow

Run these in order. If `.aws-sdlc/intent.md` is missing, do not refuse: ask the
1–3 questions you need (scale, data sensitivity, budget, team language) or infer
them from the existing codebase, then continue.

1. **Read the intent.** Load `.aws-sdlc/intent.md`. Pull out the components,
   the recommended architecture, the NFRs (scale, latency, data sensitivity,
   compliance, budget), and the team's languages. Exit: you can name every
   resource the build must produce.
2. **Pick the IaC tool by context, not dogma.** Recommend one with a reason;
   name the runner-up. CDK when the team codes in a supported language and wants
   logic and reuse; CloudFormation/SAM when they want declarative templates or
   SAM's local-invoke loop for serverless; AWS Blocks for a full-stack app that
   should follow a paved pattern. Route to the owning skill (see Routing). Exit:
   the IaC tool is chosen and its skill is loaded.
3. **Scaffold and synth empty.** Create the project skeleton and confirm it
   synthesizes/validates with no resources before adding any. Exit: a clean
   `cdk synth` / `sam validate` / template lint on an empty stack.
4. **Build one resource group at a time.** Add a small, coherent slice
   (one component or one wiring), then synth. Never batch the whole stack into
   one unsynthesized change. For each service, route to its domain skill for the
   recommended shape. Exit: each increment synthesizes cleanly before the next.
5. **Write the application code.** Route to the SDK skill for the team's
   language. Keep handlers thin, config in environment, no hardcoded ARNs or
   account IDs. Exit: app code builds and references resources by reference,
   not literal.
6. **Wire IAM least-privilege.** Give every role only the actions and resources
   it uses; no `*` resource on a principal you control. Route to **aws-iam**.
   Exit: no wildcard resource policies, no admin-equivalent roles.
7. **Wire secrets.** No secret in code, template, or env literal. Store in
   Secrets Manager and reference by ARN. In IaC, create the secret with a generated value (CDK
   `secretsmanager.Secret`, CloudFormation `GenerateSecretString`) and grant `secretsmanager:GetSecretValue`
   on that ARN only; CloudFormation cannot create SSM SecureString parameters, so never ship a plaintext
   String parameter with a placeholder. Grant data access by verb (for example `grantWriteData` for a
   writer), not full read/write. Route to
   **creating-secrets-using-best-practices**. Exit: no plaintext secrets in
   the tree.
8. **Add unit tests for the logic you wrote.** At minimum: every auth or validation branch
   (for example a valid, an invalid and a missing signature), the happy path, and malformed input, plus an
   IaC assertion test (CDK `Template.fromStack` or cfn-guard) for removal policies, auth type and IAM scope.
   Exit: the test command runs green and is recorded in `build.md`.
9. **Final synth and record.** Synthesize the whole stack once more, then write
   `.aws-sdlc/build.md` from the template: what was built, the resource list,
   the IaC tool, and the exact command to synth. Exit: `build.md` exists with
   `next: aws-verify`.

## Routing

Pick by what the signal commits to; full table with reasons in
[references/routing.md](references/routing.md).

| Signal | Route to |
|---|---|
| CDK in a supported language | aws-cdk |
| CloudFormation / SAM templates | aws-cloudformation, aws-serverless (SAM, local invoke) |
| Full-stack paved pattern | aws-blocks |
| App code | aws-sdk-python-usage, aws-sdk-js-v3-usage, aws-sdk-swift-usage |
| IAM roles and policies | aws-iam |
| Secrets | creating-secrets-using-best-practices (specialized) |
| Service depth | aws-serverless, aws-compute, aws-containers, aws-database, aws-storage, aws-messaging-and-streaming, aws-networking, amazon-bedrock, aws-ai-ml |

## Artifact

Write [.aws-sdlc/build.md](assets/build-template.md) using the bundled template.
It feeds **aws-verify**.

## Using the AWS MCP Server

This plugin configures the AWS MCP Server. Prefer its tools over the local AWS CLI when they are available:

- `aws___search_documentation`, `aws___read_documentation`, `aws___get_regional_availability`, `aws___list_regions`: live facts (limits, pricing, regions, new launches). No credentials needed.
- `aws___run_script`: sandboxed Python with `await call_boto3(service_name=..., operation_name=...)` (see the tool description for parameters) under the user's IAM credentials. Every call is logged in CloudTrail and carries the `aws:ViaAWSMCPService` / `aws:CalledViaAWSMCP` condition keys, so agent actions stay auditable.
- `aws___retrieve_skill(skill_name=...)`: load a routed skill that is not installed locally (pass `file="references/..."` for its reference files). When a phase routes to a skill, load it (locally or through `aws___retrieve_skill`) before acting in its domain; do not work from memory, because services launched after the model's training cutoff are where memory is wrong.

Use the documentation tools for current API shapes and new features. Building writes files, not resources: do not create resources here; `aws-deploy` does that. If the MCP server is not connected, fall back to the AWS CLI with the same read-only-by-default rule.

## Rules

- **End every reply with the next step.** Last line, exactly this shape: `Next → aws-verify: say "Verify it before we ship."`. If this phase is blocked or failed, name the fix instead (for example `Next → fix the 3 RED items, then re-run the review`).
- **Recommend, don't mandate.** Give options with trade-offs, make one
  opinionated recommendation with a reason, and defer service-level choices to
  the domain routers.
- **Route, don't duplicate.** Once a skill is chosen, follow it instead of
  re-deriving its content here.
- **Ground facts in live docs.** Limits, pricing, regional availability, and
  newly launched features come from the AWS MCP Server tools
  (`search_documentation`, `read_documentation`, `get_regional_availability`),
  not training data.
- **Small increments that synth clean.** Never hand off a stack that has not
  synthesized since the last change.
- **No mutating AWS calls without explicit user confirmation.** Build and synth
  are local; deploying is aws-deploy's job.
- **If a routed skill isn't installed,** still give the phase answer and name
  the skill that would go deeper.
- **Least-privilege and no plaintext secrets are build-time defaults,** not
  verify-time fixes.
