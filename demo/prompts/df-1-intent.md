---
description: "Durable Functions flow, step 1 (intent): describe the team photo wall"
---
I want to build a photo wall for our team. Someone uploads a photo, we make a thumbnail, have AI write a short caption, then wait for a moderator to approve it (up to 10 minutes, otherwise it is rejected and the uploader is told). Approved photos go on the wall and the team gets one notification. Any step can fail and retry, but a photo must never be posted twice or announced twice. About 200 photos a day, Python team, us-west-2, budget under $10/month. Pick the recommendation yourself; I accept it.
