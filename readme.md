# Orkes Conductor CI/CD Example

This project demonstrates how an end-to-end CI/CD pipeline for promoting resources between clusters can work.
There are various methods of achieving the same goal and this example has selected the following design choices:
1. Clusters are represented by branches e.g. `env/uat` and a corresponding GitHub environment
2. A manual trigger action is used as the initiation to promote resources between 2 environments (e.g. dev -> uat)
3. Tagging used to categorise resources for extraction
4. Definitions for tagged resources are extracted from source cluster
5. A new branch is created and the definitions are saved and committed to the branch
6. A pull request created from the new branch
7. When the pull request is merged, the `Deploy Changes` action triggers
8. This deploys or updates the resources in the target cluster

## Repository Setup
### Environments and Branches
1 per cluster: e.g. a `uat` environment and a `env/uat` branch

### Secrets
Each cluster needs to have an application with admin role created and credentials saved as GitHub environment secrets
- `CLUSTER` (e.g. `https://abc.orkesconductor.io/api`)
- `KEY_ID`
- `SECRET`

## Trigger
[Start the Initialise Pull Request action](../../../actions/workflows/init-pr.yaml) with these inputs:
- `Use workflow from` selects the target cluster (source is derived - e.g. dev -> uat)
- `Description` e.g. `Deploy new ecommerce changes`
- `Tag Key` e.g. `app`
- `Tag Value` e.g. `ecommerce`

## Extraction
- The opinionated approach in this example uses tagging to categorise resources.
- All workflows, tasks, user forms, webhooks, schedulers, AI prompts, and event-handlers in the source cluster tagged with the selected tag will have their definitions extracted and written to a local directory (e.g. `./workflow/my-workflow.json`)
- Environment variables, secrets, integrations and users/groups are excluded as they tend to be environment specific so promoting them between clusters does not make much sense

## Branch and Pull Request creation
- Once the resources are extracted, a new branch named after the input description is created
- A Pull Request to the target environment branch is created

## Deployment
- Once the PR is merged, the `Deploy Changes` action triggers
- This looks up all the changed JSON files in the latest commit
- For each file, deploy it to the target cluster and update the tagging to mirror the source
