# deployer

[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![semantic-release: node](https://img.shields.io/badge/semantic--release-node-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

<p align="center">
  <img width="320" src="docs/images/deployer.png" alt="eo-deployer" />
  <p align="center">Deploy from a pull request</p>
  <br />
</p>

## Create a deployment

1. Dispatch workflow `deployer-pull-request.yml`

   ```bash
   gh workflow run deployer-pull-request.yml
   ```

2. Goto **"Pull requests"** tab in GitHub and wait until pull request is created
3. Open pull request `chore(ci): repo deployment` and select which repositories to deploy
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
