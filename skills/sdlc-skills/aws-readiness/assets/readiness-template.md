---
phase: readiness
status: draft
updated: <ISO date>
inputs: [intent.md, build.md, verify-report.md]
next: aws-deploy
---

> Next step: invoke the `aws-deploy` skill. It reads this file. If the user asked for a specific phase, invoke that phase's skill instead.

# Operational Readiness Review — <workload name>

- **Criticality tier:** <prototype | internal | customer-facing | critical>
- **Item set run:** <e.g. P+I+C — N items>
- **Overall:** <READY | READY WITH FOLLOW-UPS | BLOCKED>
  - BLOCKED if any item below is RED. Set the header `status: blocked`.

## Summary

| Result | Count |
|---|---|
| GREEN | <n> |
| YELLOW | <n> |
| RED | <n> |

One-line verdict: <e.g. "Blocked: no tested rollback (RDY-DEP-3) and wildcard IAM (RDY-SEC-1).">

## Scores

Fill one row per item from the tier's set. Evidence = a repo file path or a read-only AWS check and
its result. YELLOW and RED rows need an owner; YELLOW also needs a date. Route names the skill that
closes the gap.

| ID | Item | Score | Evidence | Owner | Date | Route |
|---|---|---|---|---|---|---|
| RDY-OWN-1 | Named owning team | <GREEN/YELLOW/RED> | <file or check> | <owner or —> | <date or —> | <skill or —> |
| RDY-OBS-1 | Logs per component | | | | | |
| RDY-ALM-1 | Alarm on customer-impacting metric | | | | | |
| RDY-DEP-1 | Separate environments | | | | | |
| RDY-SEC-1 | Least-privilege IAM | | | | | |
| RDY-COST-1 | Budget with alert | | | | | |
| <add rows for the tier's remaining items> | | | | | | |

## Blocking items (RED)

- <ID — what is missing, the evidence gap, and the skill that fixes it. Remove if none.>

## Follow-ups (YELLOW)

- <ID — gap, owner, target date, route. Remove if none.>

## Re-run diff (maintain mode)

Only when a prior `readiness.md` existed. Note changes since the last review.

| ID | Previous | Now | Change |
|---|---|---|---|
| <ID> | <GREEN/YELLOW/RED> | <GREEN/YELLOW/RED> | <improved / regressed / new item> |
