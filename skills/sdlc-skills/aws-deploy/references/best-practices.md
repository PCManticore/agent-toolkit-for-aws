# Deploy best practices

The deploy phase covers the Well-Architected **Operational Excellence** slice about getting change
into production safely and reversibly. Keep it concise; defer mechanics to the routed skills.

## Environments

- **Isolate environments, ideally by account.** Separate AWS accounts for dev, staging, and prod give
  the strongest blast-radius and credential separation; at minimum use separate stacks and state.
  https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html
- **Promote the same artifact.** Deploy the identical build through dev → staging → prod; rebuilding
  per environment invites drift.

## Preview before apply

- **Always diff first.** A change set (`cloudformation`), `cdk diff`, or SAM change-set confirmation
  shows what will be created, modified, replaced, or deleted. Replacement and deletion are the
  dangerous rows — call them out.
  https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html
- **Confirm every mutation.** Get explicit user go-ahead before the first mutating call and before any
  replace/delete. Previews are read-only; applies are not.

## Staged rollout

- **Shift traffic gradually and watch alarms.** Canary or linear with a bake window lets a bad deploy
  show itself on a slice of traffic. Match the mechanism to the compute type (see routing.md).
  https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html
- **Wire automatic rollback to an alarm.** The fastest rollback needs no human. Tie the deployment to
  the alarms the ORR confirmed exist.
  https://docs.aws.amazon.com/codedeploy/latest/userguide/deployments-rollback-and-redeploy.html

## Rollback plan (written before the deploy)

- **Name the trigger, the steps, and the data risk.** Which alarm or signal triggers it; the exact
  steps (previous Lambda version/alias, change-set rollback, pipeline stop, redeploy last-good); and
  whether a schema or data migration makes rollback one-way. A forward-only migration must be
  backward-compatible or the rollback is a lie.

## After the deploy

- **Smoke check read-only.** Hit a health path, `describe`/`invoke` a canary, confirm key alarms are
  still OK. On failure, execute the rollback plan rather than debugging in place.
- **Record it.** `deploy-record.md` captures what shipped, where, how it rolled out, and the rollback
  plan, then hands off to `aws-maintain`.
- **Ground changing facts in live docs.** Traffic-shift options, deploy quotas, and regional
  availability change — confirm through the AWS MCP Server, not memory.
