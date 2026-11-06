---
description: "Durable Functions flow, step 2 (build): CDK + Python durable function, unit tests"
---
Build it. Use CDK in TypeScript for the infrastructure and Python for the function code, stack name SdlcDemoOrders, tag every resource project=sdlc-demo, and nothing retained on delete. Fake the payment provider and the barista so a test event controls whether payment succeeds and whether the barista accepts. Add unit tests, make sure the stack synthesizes, and don't deploy yet.
