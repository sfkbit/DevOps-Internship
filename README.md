# Sprint 9: Infrastructure Governance & Automated Drift Detection

## Overview

This project demonstrates how Terraform can identify infrastructure changes made outside Terraform and send an alert containing the proposed configuration difference.

The project uses Docker for local infrastructure testing, a Bash script for detection and alerting, and GitHub Actions for automated execution.

## Technologies

- Terraform
- Docker
- Bash
- Python 3
- GitHub Actions
- HTTP webhooks

## Project Structure

```text
sprint-9/
├── .gitignore
├── README.md
├── proof/
│   ├── drift-report.txt
│   └── webhook-response.txt
├── scripts/
│   └── detect-drift.sh
└── terraform/
    ├── main.tf
    └── .terraform.lock.hcl
```

The GitHub Actions workflow is stored at the repository root in `.github/workflows/drift-detection.yml`.

## How It Works

1. Terraform provisions an Nginx Docker image and container.
2. A manual change modifies the container's restart policy outside Terraform.
3. The detection script creates a Terraform plan and inspects its JSON representation to identify proposed resource changes.
4. The script records the formatted plan.
5. When changes are detected, it sends a JSON alert containing the plan report to a configured webhook.
6. GitHub Actions automates the test and uploads available proof files.

## Terraform Exit Codes

The standard `terraform plan -detailed-exitcode` command returns:

| Exit code | Meaning |
|---|---|
| `0` | No changes are proposed |
| `1` | An error occurred |
| `2` | Changes are proposed |

The script uses a saved plan and its JSON representation to count resources with proposed actions. This is useful for identifying changes, but proposed changes are not necessarily unauthorized drift. The plan must be reviewed to understand why the changes are needed.

## Local Setup

### Prerequisites

Install Docker, Terraform, Python 3, Bash, and curl.

### Initialize and provision

```bash
cd sprint-9/terraform
terraform init
terraform validate
terraform apply
```

Review the plan before approving any changes.

### Simulate a manual change

Change the container restart policy directly through Docker:

```bash
docker update --restart always sprint-9-drift-test
```

Verify it:

```bash
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' sprint-9-drift-test
```

The expected value is `always`.

### Run drift detection

```bash
cd ../scripts
chmod +x detect-drift.sh
./detect-drift.sh
```

Set `WEBHOOK_URL` in the shell before running the detector if webhook alerting is required.

The expected Terraform difference is similar to:

```text
restart = "always" -> "no"
```

The detector saves the formatted plan to `proof/drift-report.txt` and sends an alert if changes are detected.

## Webhook Alerts

Configure a webhook receiver and set the `WEBHOOK_URL` environment variable. The script sends a JSON payload containing the project name, event type, resource-change count, and formatted Terraform report.

An HTTP 2xx response means the receiver accepted the request. Verify the received payload to confirm that it contains the expected difference.

Never commit webhook URLs, credentials, Terraform state, or generated plan files.

## GitHub Actions

The scheduled workflow is stored at `.github/workflows/drift-detection.yml`.

It supports manual execution and a daily schedule at 02:00 UTC (07:30 IST). The workflow provisions a temporary test environment, simulates a manual Docker change, runs the detector, sends an alert, and uploads available proof files.

A repository Actions secret named `WEBHOOK_URL` must be configured before the workflow runs.

The workflow was tested successfully on GitHub Actions, including the detection of one proposed resource change and a successful webhook request.

## Evidence

- `proof/drift-report.txt` — formatted Terraform plan showing the proposed difference.
- `proof/webhook-response.txt` — response from the webhook receiver.
- GitHub Actions run logs and uploaded artifacts — evidence of the automated test.

## Limitations

- Testing uses Docker rather than live AWS infrastructure.
- The GitHub-hosted workflow creates a fresh temporary environment and deliberately simulates a change. It demonstrates automated detection and alert delivery but does not monitor the persistent WSL environment.
- A proposed Terraform change does not by itself establish whether a change was unauthorized.
- webhook.site is suitable for testing, not production alerting.
- Production infrastructure monitoring, persistent remote state, and real-world authorization auditing are outside this demonstration's scope.

