# Update Umbrel App Action

This GitHub Action automatically synchronises the`version` field in your `umbrel-app.yml` file with the Docker image
version specified in the corresponding `docker-compose.yml` file.

It's designed to work seamlessly with Dependabot, which automatically creates pull requests to update Docker image 
versions. When Dependabot opens a PR, this action will update the app manifest to match, keeping everything in sync.

## How It Works

The action performs the following steps:

1.  Searches for all modified `docker-compose.yml` files.
2.  For each modified Compose file, it extracts the version tag from the Docker image of the specified service.
3.  It finds the corresponding `umbrel-app.yml` file in the same directory.
4.  It updates the`version` field in the `umbrel-app.yml` file.
5.  Finally, it commits the changes back to the current branch.

## Prerequisites

For the action to work correctly, your repository should follow a standard Umbrel App structure where each app resides 
in its own directory, containing both its `docker-compose.yml` and `umbrel-app.yml` files.

```
my-umbrel-app-store/
├── my-first-app/
│   ├── docker-compose.yml
│   └── umbrel-app.yml
├── my-second-app/
│   ├── docker-compose.yml
│   └── umbrel-app.yml
└── .github/
    └── workflows/
        └── update_versions.yml
```

## Inputs

| Name                  | Required | Description                                                                                      |
|-----------------------|----------|--------------------------------------------------------------------------------------------------|
| `source_service_name` | `true`   | The name of the service in the `docker-compose.yml` files whose image version you want to track. |

## Example Workflow

Below is an example workflow that runs whenever a pull request is opened or updated, specifically for changes initiated 
by Dependabot.

A working example can be found in the [Metrics Umbrel App Store](https://github.com/CPardi/metrics-umbrel-store/tree/master/.github) 
repository.

```yaml
name: Sync umbrel-app.yml Version

on:
  pull_request:
    types: [ opened, synchronize, reopened ]

jobs:
  update-umbrel-app:
    # Only run for pull requests created by Dependabot.
    # Remove this line to run the action on all pull requests.
    if: github.actor == 'dependabot[bot]'

    runs-on: ubuntu-latest

    # Required to allow the action to commit changes to the branch.
    permissions:
      contents: write

    steps:
      # 1. Check out the pull request branch
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}

      # 2. Run the update action
      - uses: CPardi/update-umbrel-app-action@v0
        with:
          # The service name in docker-compose.yml to source the version from
          source_service_name: web
```

## Example Dependabot Configuration

To automate the process of keeping your Docker images up to date, add a `.github/dependabot.yml` file to your 
repository. This configuration is a great starting point for an Umbrel App Store repository.

It will:

- Update Docker image versions in all subdirectories.
- Update your GitHub Actions workflows.

```yaml
version: 2
updates:
  # Update Docker Compose files in all subdirectories
  - package-ecosystem: "docker-compose"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
    # Group all Docker updates into a single PR for easier management
    groups:
      docker-dependencies:
        patterns:
          - "*"

  # Update GitHub Actions used in your workflows
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
    groups:
      github-actions-dependencies:
        patterns:
          - "*"
```
