# deployer

[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![semantic-release: node](https://img.shields.io/badge/semantic--release-node-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

<p align="center">
  <img width="320" src="docs/images/deployer.png" alt="eo-deployer" />
  <p align="center">Deploy from a pull request</p>
  <br />
</p>

## Create a batch deployment

1. Dispatch workflow `deployer-pull-request.yml`

   ```bash
   gh workflow run deployer-pull-request.yml -f team_slug="<team-slug>"
   ```

2. Goto **"Pull requests"** tab in GitHub and wait until pull request is created
3. Open pull request `chore(cd): repo deployment` and select which repositories to deploy

   **Example**

   ![Deployer checklist](docs/images/deployer-checklist.png)

4. Wait until list of repositories is created
5. Click `Squash and merge`
6. Wait for all selected repositories to be deployed, label with date deployed is added to closed pull request

   **Example**

   ![Deployed repositories PR](docs/images/deployed-repo-pr.png)

## Pull request flow

```mermaid
stateDiagram-v2
    dsp: Dispatch list of repos to deploy
    pr: Pull request
    cpr: Create pull request
    epr: Edit pull request
    mpr: Merge pull request
    [*] --> cpr: workflow_dispatch
    cpr --> pr:Create checklist of team repos
    pr --> epr
    epr --> pr: changes
    pr --> mpr
    mpr --> dsp: closed
    dsp --> [*]:workflow_dispatch
```

## Dispatch deployment

Selected repositories with workflow `deploy.yml` will automatically start deploy.

### Closed pull request

Once deployment is complete, the closed pull request is labeled with id for the deployment.

![Closed pull request](docs/images/deployed-closed-pr.png)

### Summary

Summary for each batch with a link back to pull request that iniated the deployment.

![Link to pull request](docs/images/deployment-id-pr.png)