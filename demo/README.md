# Demo: the AWS SDLC skills, from intent to maintain

A 5–8 minute live demo. One agent session takes a new workload from an idea to production by walking
the SDLC phases: **intent → build → verify → ORR → deploy → maintain**. Two ready-made flows:

- **Flow A (main): a team photo wall on Lambda Durable Functions.** Multi-step, retries, a 10-minute
  wait for a moderator, and a hard "never post or announce twice" rule.
- **Flow B (alternative): Pulse, a live Q&A board for events on Lambda Web Functions** (launched
  October 2026). The audience votes from their phones while the projector re-ranks questions live.

## What the audience should notice

1. **Only seven skills are installed**, one per SDLC phase. The agent starts from where you are in the
   lifecycle, not from a list of services.
2. **Service depth comes from the AWS MCP Server on demand.** Intent routes to `aws-serverless`, which
   picks Durable Functions (or Web Functions). Build then pulls that service's skill with
   `retrieve_skill`. These services are newer than the model's training data, so without the skill
   the agent would guess.
3. **Every phase leaves an artifact** in `.aws-sdlc/` that the next phase reads
   (`intent.md`, `build.md`, `verify-report.md`, `orr.md`, `deploy-record.md`, `maintain-log.md`).
4. **The ORR is a gate.** `aws-deploy` refuses to ship to production while the readiness review has a
   RED item, then ships once the items are fixed.
5. **Every AWS call goes through the AWS MCP Server** under your own IAM, so it is logged in CloudTrail
   and carries the `aws:ViaAWSMCPService` condition key.

## Setup (once, before the demo)

```bash
tools/dev/setup-demo.sh /path/to/demo-run     # prints the commands below
cd /path/to/demo-run
./claude-demo      # Claude Code: only the aws-sdlc skills, tools auto-approved
./kiro-demo        # or Kiro CLI: only the aws-sdlc skills, all tools trusted
```

- **Isolation.** Claude Code runs with its own config dir and Kiro CLI with its own `KIRO_HOME`, so none
  of your personal skills, plugins or steering files load. Check by asking *What skills do you have?*:
  expect `aws-sdlc`, `aws-intent`, `aws-build`, `aws-verify`, `aws-orr`, `aws-deploy`, `aws-maintain`.
- **Auto-accept.** Claude Code uses the workspace `.claude/settings.json`: edits are accepted and shell,
  file and AWS MCP tools are pre-approved. Destructive commands (`kill`, stack deletes, `git push`) are
  denied. Kiro runs with `--trust-all-tools`.
- **Ports.** Local servers use port 8787. Nothing touches port 3000.
- **AWS.** Uses your current credentials in us-west-2. Every resource is named `SdlcDemo*` and tagged
  `project=sdlc-demo`.

`./claude-demo` and `./kiro-demo` open with a how-to screen (`WELCOME.txt`): the phases, the artifact each
writes, and the slash commands. Press Enter to start the agent. Inside a session, `/demo-help` asks the
agent to explain the plugin and where the project is in the lifecycle.

Every prompt below is also a slash command in both agents. Type `/demo-1-intent` instead of pasting.

## Flow A: team photo wall on Lambda Durable Functions

| # | Say | Type (slash command and prompt) | Expect |
|---|---|---|---|
| 0 | "Seven skills, one per phase." | `/demo-0-start`: *I want to build something new on AWS. Where do I start, and what does the lifecycle look like?* | `aws-sdlc` shows the lifecycle map and points to intent |
| 1 | "I describe the problem. I don't name a service." | `/demo-1-intent`: *I want to build a photo wall for our team. Someone uploads a photo, we make a thumbnail, have AI write a short caption, then wait for a moderator to approve it (up to 10 minutes, otherwise it is rejected and the uploader is told). Approved photos go on the wall and the team gets one notification. Any step can fail and retry, but a photo must never be posted twice or announced twice. About 200 photos a day, Python team, us-west-2, budget under $10/month. Pick the recommendation yourself; I accept it.* | `aws-intent` pulls `aws-serverless` from the MCP server, compares **Durable Functions** with Step Functions, and recommends one with reasons. `intent.md` has requirements, options, cost and doc sources |
| 2 | "Now it pulls the skill for the service it picked." | `/demo-2-build`: *Build it. Use CDK in TypeScript for the infrastructure and Python for the function code, stack name SdlcDemoPhotos, tag every resource project=sdlc-demo, and nothing retained on delete. Fake the moderator so a test event controls whether the photo is approved. Add unit tests, make sure the stack synthesizes, and don't deploy yet.* | `aws-build` retrieves `aws-lambda-durable-functions`, writes the handler with steps and a wait, an idempotency key on the post and the notification, CDK and tests. Writes `build.md` |
| 3 | "Verify is evidence, not opinion." | `/demo-3-verify`: *Verify it before we ship. Deploy a dev copy as stack SdlcDemoPhotos-dev in us-west-2 and run two uploads end to end: one the moderator approves, and one nobody approves so it is rejected. Show me where each execution checkpointed.* | PASS/FAIL/SKIPPED per check with the command that proved it. Execution history shows completed steps and the wait |
| 4 | "Would you open this to everyone?" | `/demo-4-orr`: *We open this to the whole team next week. Are we operationally ready? Check the dev stack read-only. Owner is the platform team; on-call is their pager rotation; there are no runbooks yet.* | `aws-orr` checks the account read-only through `run_script`. Expect RED items such as no alarms or runbooks, so `orr.md` is `blocked` |
| 5 | "Watch the gate." | `/demo-5-deploy`: *Ship it to production as stack SdlcDemoPhotos.* | `aws-deploy` refuses: the ORR is blocked |
| 5b | "Fix, review again, ship." | `/demo-5b-fix-and-deploy`: *Fix the RED items from the ORR, re-run the ORR, and if it passes deploy to production as stack SdlcDemoPhotos with a rollback plan.* | Alarms and runbooks added, ORR passes, change set previewed, deploy, smoke check, `deploy-record.md` |
| 6 | "Day 2." | `/demo-6-maintain`: *Some photos have been waiting for an hour and people say the same photo was announced twice. Triage it.* | `aws-maintain` reads metrics, logs and execution history through the MCP server, checks the waits and the idempotency keys, proposes a fix and logs it in `maintain-log.md` |

## Flow B: Pulse on Lambda Web Functions

Same phases, different app. Use the `wf-` commands.

| # | Type | Expect |
|---|---|---|
| 1 | `/demo-wf-1-intent`: *I want to build Pulse, a live Q&A board for our company events. People open a link on their phone, post a question and upvote other questions. The big screen shows the top questions re-ranking live as votes come in, and a "Summarize" button streams an AI summary of what people are asking, token by token. Expect about 300 people for one hour, a public link with no login, Node.js, us-west-2, budget a few dollars. Pick the recommendation yourself; I accept it.* | Routes to **Web Functions** (Node.js server plus server-sent events), DynamoDB and Bedrock. Names the abuse limits a public link needs |
| 2 | `/demo-wf-2-build`: *Build it. Use CDK in TypeScript, stack name SdlcDemoPulse, tag every resource project=sdlc-demo, and nothing retained on delete. Make the UI look good on a phone and on a projector. Run it locally on port 8787 to check it works, make sure the stack synthesizes, and don't deploy yet.* | Retrieves `aws-lambda-web-functions`, writes an Express app and CDK, runs it locally on 8787 |
| 3 | `/demo-wf-3-verify`: *Verify it before we ship. Deploy a dev copy as stack SdlcDemoPulse-dev in us-west-2 for the integration tests, and give me its URL.* | Dev URL to open on screen |
| 4 | `/demo-wf-4-orr`: *We go live at our next company event with about 300 people on a public link. Are we operationally ready? Check the dev stack read-only. Owner is the demo team; there is no on-call rotation.* | RED items such as no alarms or no rate limit |
| 5 | `/demo-wf-5-deploy`, then `/demo-wf-5b-fix-and-deploy` | Gate refuses, then ships and returns a URL for a QR code. Let the room vote |
| 6 | `/demo-wf-6-maintain`: *People in the room say Pulse got slow and some votes don't show up. Triage it.* | Routes to the Web Functions concurrency and troubleshooting references |

## Timing

Build and verify take several minutes each with real deploys. For a 5-minute slot, run intent live,
then switch to a workspace prepared earlier (same flow, already at `orr.md`) and run 5 → 5b → 6 live.
To prepare it, run the flow once in a second demo workspace the day before.

## Backup prompts

- If intent does not pick the expected service, add *"Use the newest Lambda option for this."*
- *What skills do you have available?* shows the isolation.
- *Which AWS MCP Server tools did you use in this session, and what did each one do?*
- *Show me the .aws-sdlc artifacts and what each phase wrote.*

## Teardown

```bash
./teardown.sh      # deletes SdlcDemo* stacks and sdlc-demo* web functions in us-west-2
```
