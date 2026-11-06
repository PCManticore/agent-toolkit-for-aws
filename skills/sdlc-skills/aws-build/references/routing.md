# aws-build routing

Signal → existing skill. Every skill below was verified to exist in this repo.
Core skills ship with the **aws-core** plugin. Specialized skills live under
`skills/specialized-skills/`; the plugin that provides each non-core skill is
noted.

## Infrastructure-as-code tool

| Signal | Route to | Why |
|---|---|---|
| Team codes in Python/TypeScript/Java/Go/C#/.NET and wants loops, conditionals, and reusable constructs | **aws-cdk** | Programmatic IaC; synthesizes to CloudFormation. Best when infrastructure benefits from real code and shared constructs. |
| Team wants declarative templates, or must match an existing CloudFormation estate | **aws-cloudformation** | Plain templates, change sets, drift detection. No build step, no language runtime. |
| Serverless app that wants a fast local build/invoke loop | **aws-serverless** | Owns the SAM and CDK deployment references for Lambda/API Gateway/EventBridge, plus `sam local invoke`. SAM is CloudFormation underneath. |
| Full-stack app that should follow a paved, opinionated pattern | **aws-blocks** | Composable full-stack building blocks; least custom IaC to maintain. |

There is no dedicated SAM skill. Route SAM questions to **aws-serverless**
(deployment reference) and **aws-cloudformation** for the template mechanics.

## Application code (by language)

| Signal | Route to |
|---|---|
| Python app/handler code | **aws-sdk-python-usage** |
| JavaScript/TypeScript app/handler code | **aws-sdk-js-v3-usage** |
| Swift app code | **aws-sdk-swift-usage** |

## Security wiring (always, every build)

| Signal | Route to | Why |
|---|---|---|
| Roles, policies, permission boundaries, least-privilege review | **aws-iam** | Scope every role to the actions and resources it uses; IAM Access Analyzer policy validation. |
| Any secret, credential, API key, connection string | **creating-secrets-using-best-practices** (specialized: security-and-identity-skills) | Store in Secrets Manager / SSM SecureString, reference by ARN, rotate. Never in code or templates. |
| Broader security posture (encryption, CloudTrail, baseline) | **aws-security** | Encryption at rest/in transit defaults, account baseline. |

## Service depth (route per component)

| Component | Route to |
|---|---|
| Lambda, API Gateway, EventBridge, Step Functions, event-driven | **aws-serverless** (router to serverless specialized skills) |
| EC2, general compute selection | **aws-compute** |
| ECS / EKS / Fargate containers | **aws-containers** |
| Databases (selection and service) | **aws-database** |
| S3 and storage | **aws-storage** |
| SNS / SQS / Kinesis / messaging and streaming | **aws-messaging-and-streaming** |
| VPC, networking, content delivery | **aws-networking** |
| Bedrock / generative AI | **amazon-bedrock** |
| ML workloads | **aws-ai-ml** |

## Rule

If a routed skill is not installed in the current environment, still give the
build answer from this skill and name the skill that would go deeper. Do not
switch to a different service because its docs are easier to reach.
