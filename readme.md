# Orkes Conductor CI/CD Example

This project demonstrates how an end-to-end CI/CD pipeline for promoting resources between clusters can work.

There are various methods of achieving the same goal and this example has selected the following design choices:

1. Clusters are represented by branches and a corresponding GitHub environment
2. A manual trigger action is used as the initiation to promote resources between 2 environments
3. Tagging used to categorise resources for extraction
4. Definitions for tagged resources are extracted from source cluster
5. A new branch is created and the definitions are saved and committed to the branch
6. A pull request created from the new branch
7. When the pull request is merged, the deployment action triggers
8. This deploys or updates the resources in the target cluster

## Repository Setup
### Environments and Branches
1 x GitHub environment and branch per cluster.

This example considers the `dev` cluster to be freely accessible and not CI-controlled.

Once developers are ready to deploy their workflows and other resources, they tag the resources appropriately (e.g. `app:ecommerce`) and initiate the trigger to promote them to the next higher environment.

The `env/` prefix is used as a branch name filter so that the deployment action only triggers on branches containing that prefix.

| Environment | Branch     |
| ----------- | ---------- |
| `dev`       | N/A        |
| `uat`       | `env/uat`  |
| `prod`      | `env/prod` |

### Secrets
Each cluster needs to have an application with `ADMIN` role created and credentials saved as GitHub environment secrets
- `CLUSTER` (e.g. `https://abc.orkesconductor.io/api`)
- `KEY_ID`
- `SECRET`

## Trigger
[Start the Initialise Pull Request action](../../../actions/workflows/init-pr.yaml) with these inputs:
- `Use workflow from` selects the **target** cluster (source is derived)
- `Description` e.g. `Deploy new ecommerce changes`
- `Tag key` e.g. `app`
- `Tag value` e.g. `ecommerce`

## Extraction
- All workflows, tasks, user forms, webhooks, schedulers, AI prompts, and event-handlers in the source cluster tagged with the selected tag will have their definitions extracted and written to a local directory (e.g. `./workflow/my-workflow.json`)
- Environment variables, secrets, integrations and users/groups are excluded as they tend to be environment specific so promoting them between clusters does not make much sense

## Branch and Pull Request creation
- Once the resources are extracted, a new branch named after the input description is created
- A Pull Request to the target environment branch is created

## Deployment
- Once the PR is merged, the `Deploy Changes` action triggers
- This looks up all the changed JSON files in the latest commit
- For each file, deploy it to the target cluster and update the tags to mirror the source

## Repeat
- Resources can only be promoted in environment order i.e. `dev` -> `uat` -> `prod`
- The contents of each branch are treated as the golden source for what that cluster contains
- Different projects using different tags can be promoted independently in any order
