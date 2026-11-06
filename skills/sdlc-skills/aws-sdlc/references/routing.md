# aws-sdlc routing

Detect the phase from two signals together: the words the user uses, and which `.aws-sdlc/*.md` artifacts
already exist in the project root. Artifacts show how far the work has progressed; wording shows what the
user wants next. When they disagree, follow the wording and say what you observed.

## Phase signal table

| User signal (wording) | Artifact state | Phase skill | Why |
|---|---|---|---|
| "what should I build", "help me design", "which services", requirements, scale/latency/budget questions | no `.aws-sdlc/` or only a stale `intent.md` | `aws-intent` | Intent owns requirements, NFRs, and candidate architectures before any code. |
| "write the code", "scaffold", "generate the IaC / CDK / SAM", "implement the design" | `intent.md` present | `aws-build` | Build turns the chosen architecture into IaC and app code. |
| "review before I ship", "lint", "run tests", "check my IAM", "security scan", "will this fit my budget", "is it resilient" | `build.md` present | `aws-verify` | Verify is the pre-ship check: synth/lint/validate, least-privilege, scans, tests, cost, resilience. |
| "is this production ready", "readiness review", "can I go to prod" | `verify-report.md` present | `aws-readiness` | readiness review is the gate before a production deploy, with GREEN/YELLOW/RED evidence. |
| "deploy", "roll out", "promote to prod", "change set", "rollback plan", "set up the pipeline" | `readiness.md` present and `complete` | `aws-deploy` | Deploy runs environments, staged rollout, and rollback. |
| "operate", "add alarms", "triage this incident", "cut the bill", "handle this deprecation", "re-run the readiness review" | `deploy-record.md` present | `aws-maintain` | Maintain owns live operation and loops back to intent (new feature) or readiness (drift). |

## Loop-back rules

- `aws-maintain` → `aws-intent` when the user wants a new feature or capability.
- `aws-maintain` → `aws-readiness` when operation reveals readiness drift (new dependency, scale change, a
  failed restore test), or on a periodic cadence.
- Any phase can be entered standalone. If the upstream artifact is missing, the phase skill asks the one
  to three questions it needs, or infers them from the codebase — it does not refuse.

## When the signals conflict

- Artifacts further along than the wording (e.g. `deploy-record.md` exists but the user asks "what should
  I build") usually means a new feature or a second workload → confirm, then start at `aws-intent`.
- Wording further along than the artifacts (e.g. no `verify-report.md` but the user says "deploy to prod")
  → say the verify and readiness review gates have not run, and recommend `aws-verify` / `aws-readiness` first. The user may
  override for a non-production environment.

## Phase skills belong to this plugin

`aws-intent`, `aws-build`, `aws-verify`, `aws-readiness`, `aws-deploy`, and `aws-maintain` ship with the
`aws-sdlc` plugin. If one is not installed, name the phase, give its first step, and name the skill.
