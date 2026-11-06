# aws-intent routing

Intent decides *what* to build and *why*, not *which* service variant. For every service-level decision,
hand off to the domain router that owns it, then carry its recommendation back into the candidate
architecture. Each routed skill name below exists in this repo; the plugin is noted when it is not aws-core.

## Service decision → domain router

| Signal in the request | Route to | Plugin | Why |
|---|---|---|---|
| Event-driven, API backend, cron/jobs, Lambda, orchestration, "serverless" | `aws-serverless` | aws-core | Owns the Lambda form-factor, orchestration, eventing, and HTTP front-door decisions. |
| Long-running processes, EC2, batch, GPU, HPC, "a server" | `aws-compute` | aws-core | Owns instance-level and non-container compute. |
| ECS, EKS, Fargate, "containerize", Kubernetes | `aws-containers` | aws-core | Owns container orchestration and capacity. |
| Relational, key-value, document, cache, "where do I store the data" | `aws-database` | aws-core | Owns engine selection and data-model trade-offs. |
| Objects, files, blocks, data lake, backups | `aws-storage` | aws-core | Owns S3 / EFS / EBS / FSx choices. |
| Inference, training, GenAI, embeddings, models | `aws-ai-ml` | aws-core | Owns AI/ML service and Bedrock routing. |
| Queues, streams, pub/sub, event bus, decoupling | `aws-messaging-and-streaming` | aws-core | Owns SQS / SNS / Kinesis / MSK / EventBridge selection. |
| VPC, subnets, DNS, CloudFront, load balancing, connectivity | `aws-networking` | aws-core | Owns the network topology and edge decisions. |

## Cross-cutting routes

| Need | Route to | Plugin | Why |
|---|---|---|---|
| Estimate monthly cost, compare against a stated budget | `aws-billing-and-cost-management` | aws-core | Owns pricing lookups and cost modeling. |
| Weigh an architecture across the Well-Architected pillars | `aws-well-architected-review` | aws-core | Owns the pillar-by-pillar trade-off review. |
| Produce a threat model for the chosen architecture | `threat-modeling-with-aws-security-agent` | aws-agents-for-devsecops | Owns agent-driven threat modeling. |
| Early-stage startup constraints (speed, cost, team size, funding) | `architect-for-startups` | aws-startup-advisor | Owns startup-specific architecture guidance. |
| Least-privilege and identity shape raised during design | `aws-iam` | aws-core | Owns IAM role and policy design. |
| Encryption, secrets, data-protection questions raised during design | `aws-security` | aws-core | Owns the security baseline. |

## How to route

1. Identify each component the workload needs (compute, data, messaging, network, …).
2. For each, invoke the owning router with the functional requirements and NFRs from `intent.md`.
3. Record the router's recommended service and the one-line reason in the candidate architecture.
4. If a routed skill is not installed, still name the recommended service from the NFRs and name the
   skill that would confirm it. Do not switch to a service just because its docs are easier to reach.
