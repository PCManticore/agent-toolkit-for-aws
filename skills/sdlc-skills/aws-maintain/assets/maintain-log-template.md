---
phase: maintain
status: draft
updated: <ISO date>
inputs: [deploy-record.md, intent.md]
next: aws-orr
---

# Maintain log

Append one dated entry per loop run. Newest first. Keep evidence verbatim.

## <YYYY-MM-DD> - <loop: incident | observability | cost | security> - <short title>

- **Workload / environment:** <name, account, region>
- **Trigger:** <what prompted this entry: alarm, bill alert, review, deprecation notice>
- **Evidence:** <metrics, log excerpts, query results, versions - quoted, with source>
- **Finding:** <cause or gap, with a provenance note per claim; label unverified items>
- **Recommendation:** <options with trade-offs, one recommendation, why>
- **Action taken:** <read-only analysis | fix confirmed and applied | routed>
- **Routed to:** <skill name(s), e.g. aws-investigation, aws-billing-and-cost-management>
- **Follow-on phase:** <none | aws-intent (architecture change) | aws-build -> aws-verify -> aws-deploy (code/config fix) | re-run aws-orr (readiness drift)>
- **ORR diff:** <new RED/YELLOW items vs last orr.md, or n/a>

## <YYYY-MM-DD> - <loop> - <short title>

- **Workload / environment:**
- **Trigger:**
- **Evidence:**
- **Finding:**
- **Recommendation:**
- **Action taken:**
- **Routed to:**
- **Follow-on phase:**
- **ORR diff:**
