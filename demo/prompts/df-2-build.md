---
description: "Durable Functions flow, step 2 (build): CDK + Python durable function, unit tests"
---
Build it. Use CDK in TypeScript for the infrastructure and Python for the function code, stack name SdlcDemoPhotos, tag every resource project=sdlc-demo, and nothing retained on delete. Fake the moderator so a test event controls whether the photo is approved. Add unit tests, make sure the stack synthesizes, and don't deploy yet.
