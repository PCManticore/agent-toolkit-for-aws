---
phase: intent
status: draft
updated: <ISO date>
inputs: []
next: aws-build
---

# Intent: <workload name>

## Summary

<One or two sentences: what this builds and who uses it.>

## Functional requirements

- FR1: <what it must do>
- FR2: <...>

## Non-functional requirements

| NFR | Value | Notes |
|---|---|---|
| Scale | <steady / peak rate, data volume> | |
| Latency | <target or interactive/batch> | |
| Data sensitivity | <none / PII / regulated — which> | |
| Compliance | <none / HIPAA / PCI / residency> | |
| Budget | <monthly ceiling or "minimize"> | |
| Team skills | <what the team already runs> | |

## Criticality tier

`prototype` | `internal` | `customer-facing` | `critical`  — **chosen: <tier>**

Reason: <why this tier; read by aws-orr to scale the readiness review>

## Candidate architectures

### Option A — <name> (recommended)

- Main services: <list — each chosen via its domain router>
- Optimizes for: <cost / speed / scale / simplicity>
- Trade-off: <cost, operational load, time to build, scale ceiling, lock-in>

### Option B — <name>

- Main services: <list>
- Optimizes for: <...>
- Trade-off: <...>

### Option C — <name>

- Main services: <list>
- Optimizes for: <...>
- Trade-off: <...>

## Recommendation

**Option <X>**, because <reason tied to the NFRs; name why the closest alternative does not fit>.

## Service decisions (routed)

| Component | Recommended service | Routed via | Reason |
|---|---|---|---|
| <compute> | <service> | aws-serverless / aws-compute / aws-containers | <one line> |
| <data> | <service> | aws-database / aws-storage | <one line> |
| <messaging> | <service> | aws-messaging-and-streaming | <one line> |
| <network> | <service> | aws-networking | <one line> |

## Optional analyses

- Cost estimate: <summary or "not run"> (aws-billing-and-cost-management)
- Threat model: <summary or "not run"> (threat-modeling-with-aws-security-agent)
- Startup context: <summary or "not run"> (architect-for-startups)

## Open questions / assumptions

- <anything unanswered, with the assumption made>
