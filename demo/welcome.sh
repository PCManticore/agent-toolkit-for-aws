#!/usr/bin/env bash
# Intro screen for the AWS SDLC skills demo. Colors degrade to plain text when NO_COLOR is set.
if [[ -n "${NO_COLOR:-}" ]]; then O= W= G= D= B= R= C=; else
  O=$'\033[38;5;214m' W=$'\033[97m' G=$'\033[38;5;120m' D=$'\033[38;5;252m' B=$'\033[1m' R=$'\033[0m' C=$'\033[38;5;117m'
fi

benefit() { printf "    ${G}●${R} ${B}%-22s${R}%s\n" "$1" "$2"; [[ -n "${3:-}" ]] && printf "      %-22s%s\n" "" "$3"; }
phase() { printf "    ${O}${B}%-11s${R} %s\n" "$1" "$2"; [[ -n "${3:-}" ]] && printf "    %-11s ${D}%s${R}\n" "" "$3"; }

cat <<EOF

  ${O}${B}▲ Agent Toolkit for AWS${R}  ${D}·${R}  ${W}${B}SDLC skills${R}
  ${W}AWS best practices for every phase of building software, in any agent.${R}

  ${D}Describe what you want to build. The agent finds the phase and applies the AWS
  guidance for it: Well-Architected, least-privilege IAM, staged rollouts, readiness reviews.${R}

    ${O}intent${R} ${D}─▶${R} ${O}build${R} ${D}─▶${R} ${O}verify${R} ${D}─▶${R} ${O}readiness${R} ${D}─▶${R} ${O}deploy${R} ${D}─▶${R} ${O}maintain${R}
${D}       ▲                             ▲                      │
       └──────── new feature ────────┴── readiness drift ───┘${R}


EOF
phase "intent"    "Turns your idea into requirements and 1–3 AWS designs with trade-offs," "and recommends one (live AWS docs, pricing and regional availability)"
phase "build"     "Writes the infrastructure and app code, least-privilege from the start" "(AWS CDK, CloudFormation or SAM · AWS SDKs · IAM · Secrets Manager · unit tests)"
phase "verify"    "Proves it works before it ships, with the command behind every check" "(cdk synth, cfn-lint · IAM Access Analyzer · security scans · tests · cost vs budget)"
phase "readiness" "Checks you can run it in production; any RED item blocks the deploy" "(CloudWatch alarms · runbooks · rollback · multi-AZ · backups · CloudTrail · budgets)"
phase "deploy"    "Ships safely: previews the change, rolls out in stages, plans the rollback" "(CloudFormation change sets · Lambda aliases · CodeDeploy · ECS blue/green · smoke tests)"
phase "maintain"  "Keeps it healthy once live: triage, missing alarms, cost, upgrades" "(CloudWatch metrics and logs · X-Ray traces · Cost Explorer · runtime and engine versions)"
cat <<EOF

  ${D}Each phase routes to deeper AWS service skills (Lambda Durable Functions, Web
  Functions, DynamoDB, Bedrock, …) and records its work in ${R}${C}.aws-sdlc/${R}

  ${W}${B}What you get with the AWS MCP Server${R}
EOF
benefit "Every AWS API, today" "15,000+ APIs behind one endpoint, plus skills for newly launched" "services, loaded on demand even when the model has never seen them"
benefit "Live knowledge" "Answers from current AWS documentation, not training data"
benefit "Governance" "Every call runs under your own IAM; the ${C}aws:ViaAWSMCPService${R} and" "${C}aws:CalledViaAWSMCP${R} condition keys let you write rules just for agents"
benefit "Audit" "Every agent call is a CloudTrail event: who, what, when, via the MCP Server"
benefit "Monitoring" "Usage and errors per tool as CloudWatch metrics"
benefit "Any agent" "Open source; the same skills in Claude Code, Kiro, Cursor and Codex" "Install: ${C}aws configure agent-toolkit${R}"
cat <<EOF

  ${O}${B}▸ Just tell it what you want to build.${R}  ${D}The status bar shows the phase and what to say next.${R}

EOF
