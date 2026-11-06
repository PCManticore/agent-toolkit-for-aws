#!/usr/bin/env bash
# Intro screen for the AWS SDLC skills demo. Colors degrade to plain text when NO_COLOR is set.
if [[ -n "${NO_COLOR:-}" ]]; then O= W= G= D= B= R= C=; else
  O=$'\033[38;5;214m' W=$'\033[97m' G=$'\033[38;5;120m' D=$'\033[38;5;252m' B=$'\033[1m' R=$'\033[0m' C=$'\033[38;5;117m'
fi

phase() { printf "    ${O}${B}%-12s${R} %s\n" "$1" "$2"; [[ -n "${3:-}" ]] && printf "    %-12s ${D}%s${R}\n" "" "$3"; }

cat <<EOF

  ${O}${B}▲ Agent Toolkit for AWS${R}  ${D}·${R}  ${W}${B}SDLC skills${R}
  ${W}AWS best practices for every phase of building software, in any agent.${R}

  ${D}Describe what you want to build. The agent finds the phase and applies the AWS
  guidance for it: Well-Architected, least-privilege IAM, staged rollouts, readiness reviews.${R}

    ${O}intent${R} ${D}─▶${R} ${O}build${R} ${D}─▶${R} ${O}verify${R} ${D}─▶${R} ${O}readiness${R} ${D}─▶${R} ${O}deploy${R} ${D}─▶${R} ${O}maintain${R}
${D}       ▲                             ▲                      │
       └──────── new feature ────────┴── readiness drift ───┘${R}


EOF
phase "intent"   "Idea → requirements → AWS architecture options with trade-offs," "live pricing and regional availability, one recommendation"
phase "build"    "AWS CDK, CloudFormation or SAM · AWS SDKs · least-privilege IAM" "secrets in Secrets Manager · unit tests"
phase "verify"   "cdk synth & cfn-lint · IAM Access Analyzer · security scans" "tests against a dev stack · cost against your budget"
phase "readiness"      "Operational readiness: CloudWatch alarms, runbooks, rollback, multi-AZ," "backups, CloudTrail, budgets. Any RED item blocks production"
phase "deploy"   "Change-set preview · staged rollout (Lambda aliases, CodeDeploy," "ECS blue/green) · written rollback plan · smoke checks"
phase "maintain" "Triage from CloudWatch metrics, logs and X-Ray traces · alarm gaps" "Cost Explorer · runtime and engine upgrades"
cat <<EOF

  ${D}Each phase routes to deeper AWS service skills (Lambda Durable Functions, Web
  Functions, DynamoDB, Bedrock, …) and records its work in ${R}${C}.aws-sdlc/${R}

  ${W}${B}Why it works${R}
    ${G}●${R} ${B}AWS MCP Server${R}  One endpoint for 15,000+ AWS APIs, live AWS documentation, and
                      service skills on demand, even for services newer than the model.
    ${G}●${R} ${B}Your IAM${R}        Every call runs under your credentials, is logged in CloudTrail,
                      and carries ${C}aws:ViaAWSMCPService${R} / ${C}aws:CalledViaAWSMCP${R}.
    ${G}●${R} ${B}Agent Toolkit${R}   Open source. Same skills in Claude Code, Kiro, Cursor and Codex.
                      Install: ${C}aws configure agent-toolkit${R}

  ${O}${B}▸ Just tell it what you want to build.${R}  ${D}The status bar shows the phase and what to say next.${R}

EOF
