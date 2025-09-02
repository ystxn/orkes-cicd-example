# Orkes Conductor CI/CD Example

This project demonstrates how an end-to-end CI/CD pipeline for promoting resources between 2 clusters can work.
There are various methods of achieving the same goal and this example has selected the following design choices:
1. Manual trigger on `init-pr` action used as initiation point
2. Tagging used to categorise resources
3. Resource definitions extracted from source cluster
4. Pull request created as a result
5. When approval is granted and pull request merged, the `release` action triggers
6. This deploys the resources into the target cluster

## Repository Setup
### Secrets
- `SOURCE_CLUSTER`
- `SOURCE_KEY_ID`
- `SOURCE_SECRET`
- `TARGET_CLUSTER`
- `TARGET_KEY_ID`
- `TARGET_SECRET`

## Trigger
[Start the Initialise Pull Request action](../../actions/workflows/init-pr.yaml) with these inputs:
- `TAG_KEY` e.g. `app`
- `TAG_VALUE` e.g. `ecommerce`
- `DESCRIPTION` e.g. `Deploy new ecommerce app`
