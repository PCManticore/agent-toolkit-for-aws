# Demo: the AWS SDLC skills, from intent to maintain

One agent session takes a new app from an idea to a public URL by walking the SDLC phases:
**intent → build → verify → readiness → deploy → maintain**.

- **Flow A (main, fast): Explainer on Lambda Web Functions.** A one-page app: type the name of an AWS
  service and a plain-English explanation streams in word by word from Amazon Bedrock. One `index.js`,
  no database, no infrastructure-as-code, deployed with a single `aws lambda-web deploy`. Lambda Web
  Functions launched in October 2026, so no model has training data on them.
- **Flow B (optional, longer): team photo wall on Lambda Durable Functions.** Multi-step workflow with a
  moderator wait and a "never post twice" rule. It uses CDK and real stack deploys, so it takes much
  longer. Record it in advance if you want it.

## Why Flow A is fast

- No CDK project, no `npm install` of a toolchain: build writes one file and a `package.json`.
- Verify runs locally on port 8787 rather than deploying a dev stack.
- The intent prompt says "prototype", so the readiness review runs the short prototype checklist.
- Deploy is one command, and the first deploy creates the function, role, code bucket and endpoint.

## What the audience should notice

1. **Only seven skills are installed**, one per phase. Service depth (`aws-serverless`,
   `aws-lambda-web-functions`, `amazon-bedrock`) comes from the AWS MCP Server through `retrieve_skill`
   when a phase needs it.
2. **The agent picks the service.** Nothing in the intent prompt names Lambda, Web Functions or Bedrock.
3. **Security shows up without being asked:** a public link that calls Bedrock needs input limits, rate
   limiting and a budget, and the execution role gets only `bedrock:InvokeModelWithResponseStream` on one
   model.
4. **The readiness review is a gate.** "Ship it" is refused while the review has a RED item.
5. **Every AWS call goes through the AWS MCP Server** under your IAM, logged in CloudTrail.

## Setup (once, before the demo)

```bash
tools/dev/setup-demo.sh /path/to/demo-run
cd /path/to/demo-run
./claude-demo      # Claude Code: only the aws-sdlc skills, tools auto-approved
./kiro-demo        # or Kiro CLI
```

- Re-running `setup-demo.sh` (or `./reset.sh`) starts from a clean slate: it deletes `.aws-sdlc/` and any generated app code, so the status bar is back at ● intent. It keeps your sign-in and does not touch AWS.
- Only the seven SDLC skills load; your personal skills and plugins don't. Check with *What skills do you have?*
- Claude Code auto-approves edits, shell, file and AWS MCP tools; destructive commands are denied.
- Local servers use port 8787. Nothing touches port 3000.
- Needs Bedrock model access in us-west-2 (a Claude Haiku inference profile is enough).

Every prompt is also a slash command in both agents.

## Flow A: Explainer on Lambda Web Functions

| # | Type (slash command and prompt) | Expect |
|---|---|---|
| 1 | `/demo-1-intent`: *I want a tiny web page where someone types the name of an AWS service and gets a short plain-English explanation that streams in word by word, like a chat. Node.js, one page, no database, no login, a few dozen people from our team, us-west-2, budget a few dollars a month. It's a prototype, so keep it as small as possible. Pick the recommendation yourself; I accept it.* | Pulls `aws-serverless`, which picks **Lambda Web Functions** (Node.js server, response streaming, global HTTPS URL, scales to zero) plus **Bedrock** streaming. Tier `prototype`. `intent.md` |
| 2 | `/demo-2-build`: *Build it as small as possible: one index.js with Express and a single HTML page, no infrastructure-as-code. Use a function name starting with sdlc-demo. Run it locally on port 8787 and check that an explanation streams. Don't deploy yet.* | Pulls `aws-lambda-web-functions`. Writes `index.js` (server-sent events from Bedrock ConverseStream, `helmet`, input length limit), runs it on 8787. `build.md` |
| 3 | `/demo-3-verify`: *Verify it before we ship. Keep it local: run it on port 8787, check the stream, check the input validation, and check the IAM permissions it will need are least privilege. Don't deploy a dev stack.* | PASS/FAIL/SKIPPED per check; IAM policy validated through `run_script`. `verify-report.md` |
| 4 | `/demo-4-readiness`: *We'll share the link with the team this afternoon. Are we ready?* | Prototype checklist. Likely RED: a public endpoint with no rate limit, no budget alert. `readiness.md` blocked |
| 5 | `/demo-5-deploy`: *Ship it.* | `aws-deploy` refuses: the readiness review is blocked |
| 5b | `/demo-5b-fix-and-deploy`: *Fix the RED items from the readiness review, re-run the review, and if it passes deploy it. Give me the URL.* | Adds rate limiting and a budget, review passes, `aws lambda-web deploy`, smoke check with curl, URL. `deploy-record.md` |
| 6 | `/demo-6-maintain`: *People say some answers stop halfway through. Triage it.* | Reads logs through the MCP server; the Web Functions skill points at the request timeout covering the whole stream, not just the first byte |

For a 3-minute video: record the whole flow once, then cut the waiting. Steps 1, 5 and 5b carry the story;
show 2–4 as short clips of the status bar and the artifacts.

## Flow B: team photo wall on Lambda Durable Functions (optional, longer)

Same phases with the `df-` commands. Uses CDK and real stack deploys; allow 30+ minutes end to end.

| # | Type |
|---|---|
| 1 | `/demo-df-1-intent`: *I want to build a photo wall for our team. Someone uploads a photo, we make a thumbnail, have AI write a short caption, then wait for a moderator to approve it (up to 10 minutes, otherwise it is rejected and the uploader is told). Approved photos go on the wall and the team gets one notification. Any step can fail and retry, but a photo must never be posted twice or announced twice. About 200 photos a day, Python team, us-west-2, budget under $10/month. Pick the recommendation yourself; I accept it.* |
| 2 | `/demo-df-2-build`: CDK in TypeScript, Python durable function, a fake moderator, unit tests |
| 3 | `/demo-df-3-verify`: dev stack, one approved and one rejected upload, with checkpoints |
| 4 | `/demo-df-4-readiness`: *We open this to the whole team next week. Are we operationally ready?* |
| 5 | `/demo-df-5-deploy`, then `/demo-df-5b-fix-and-deploy` |
| 6 | `/demo-df-6-maintain`: *Some photos have been waiting for an hour and people say the same photo was announced twice. Triage it.* |

## Backup prompts

- If intent doesn't pick Web Functions: add *"Use the newest Lambda option for a Node.js web server."*
- *What skills do you have available?* shows the isolation.
- *Which AWS MCP Server tools did you use in this session, and what did each one do?*

## Teardown

```bash
./teardown.sh      # deletes SdlcDemo* stacks, sdlc-demo* web functions and their roles in us-west-2
```
