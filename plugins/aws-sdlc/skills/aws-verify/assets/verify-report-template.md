---
phase: verify
status: draft
updated: <ISO date>
inputs: [build.md]
next: aws-orr
---

# Verify report

## Summary

One or two sentences: what was verified and the overall verdict. Set
`status: blocked` above if any required rung is FAIL.

## Verification ladder

Each rung is PASS, FAIL, or SKIPPED. Record the command and a short output
summary. A rung that could not run is SKIPPED with the reason — never blank.

| # | Rung | Result | Command | Evidence (output summary) |
|---|---|---|---|---|
| 1 | Static — synth / lint / guard | PASS/FAIL/SKIPPED | `cdk synth` / `cfn-lint` / `cfn-guard` | |
| 2 | Static — IAM least-privilege | PASS/FAIL/SKIPPED | IAM Access Analyzer policy validation | |
| 3 | Security — scan | PASS/FAIL/SKIPPED | security-agent scan / diff-scan / local scanner | |
| 4 | Tests — unit | PASS/FAIL/SKIPPED | build's test command | counts |
| 5 | Tests — local invoke | PASS/FAIL/SKIPPED | `sam local invoke` | |
| 6 | Tests — integration (dev stack) | PASS/FAIL/SKIPPED | deploy + integration suite | |
| 7 | Cost — estimate vs budget | PASS/FAIL/SKIPPED | estimate; compare to intent budget | $/mo vs budget |
| 8 | Resilience — failure modes | PASS/FAIL/SKIPPED | Resilience Hub assessment / FIS experiment | |
| 9 | Optional — Well-Architected review | PASS/FAIL/SKIPPED | aws-well-architected-review | |

## Blocking failures

List every FAIL on a required rung, what it means, and what must change. If this
list is non-empty, `status` must be `blocked`.

## Cost

- **Estimate:** $X/month for the built resources.
- **Budget (from intent):** $Y/month.
- **Verdict:** under / over, and by how much.

## Resilience findings

- Single points of failure, missing backups, missing timeouts/retries, and the
  mitigations noted.

## Deferred / accepted risks

- Findings not fixed before handoff, each with an owner and a date.

## Next

Hand off to **aws-orr** for the production readiness gate. aws-orr reads this
report plus intent.md and build.md.
