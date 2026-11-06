---
name: aws-build
description: >-
  Build phase of the AWS SDLC lifecycle: turn an intent (requirements plus a
  chosen architecture) into infrastructure-as-code and application code.
  Triggers: "build it", "implement this", "write the CDK/CloudFormation/SAM",
  "scaffold the app", "stand up the resources". Picks an IaC tool by context
  (CDK, CloudFormation, SAM, or AWS Blocks) and routes to the owning skill,
  wires least-privilege IAM and secrets, builds in small increments that synth
  cleanly. Reads .aws-sdlc/intent.md, writes .aws-sdlc/build.md. Not for
  choosing the architecture (use aws-intent), pre-ship verification (use
  aws-verify), or deploying to an environment (use aws-deploy).
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
   Secrets Manager (or SSM SecureString) and reference by ARN. Route to
   **creating-secrets-using-best-practices**. Exit: no plaintext secrets in
   the tree.
8. **Final synth and record.** Synthesize the whole stack once more, then write
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

## Rules

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
