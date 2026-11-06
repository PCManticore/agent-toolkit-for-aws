# Demo workspace: AWS SDLC skills

This folder is a live demo of the `aws-sdlc` plugin. The only skills installed are the seven
SDLC phase skills (aws-sdlc, aws-intent, aws-build, aws-verify, aws-orr, aws-deploy, aws-maintain).
Domain skills such as `aws-serverless` or `aws-lambda-web-functions` are not installed: load them
on demand with the AWS MCP Server tool `aws___retrieve_skill` when a phase routes to them.

## Rules for this demo

- Follow the lifecycle. Load the phase skill that matches the request before acting, and keep the
  `.aws-sdlc/` artifacts up to date.
- AWS account and Region: use the current credentials (`aws sts get-caller-identity`) and `us-west-2`.
  This is a demo account; deploys the user asks for are pre-approved, but preview the change first.
- Name every stack and resource with the `SdlcDemo` / `sdlc-demo` prefix and tag it `project=sdlc-demo`,
  so `./teardown.sh` can find and delete it. Nothing may be retained on delete.
- Local servers: never use port 3000 and never stop a process you did not start (port 3000 runs
  KiRoom). Use port 8787: `AWS_LAMBDA_HTTP_ENDPOINT=127.0.0.1:8787 node index.js`. Run local servers
  under `timeout 60` so they stop on their own (`kill` is blocked in this workspace).
- Never print a secret value in the transcript, a command line or an artifact.
- Do not delete stacks or resources; the presenter runs `./teardown.sh` at the end.
