---
description: "Durable Functions flow, step 1 (intent): describe the coffee order workflow"
---
I want to build the order workflow for our coffee shop app. When a customer orders, we validate the order, charge their card through our payment provider, wait for the barista to accept it (up to 10 minutes, otherwise refund the customer), then notify the customer and add loyalty points. Any step can fail and retry, but a customer must never be charged twice. About 2,000 orders a day with a lunch peak, Python team, us-west-2, budget under $20/month. Pick the recommendation yourself; I accept it.
