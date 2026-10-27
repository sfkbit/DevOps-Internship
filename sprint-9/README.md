
# Sprint 9: Infrastructure Governance & Automated Drift Detection

## Overview

This project demonstrates how Terraform can detect infrastructure changes made outside Terraform and send an alert containing the proposed configuration difference.

It uses Docker for local infrastructure, Terraform for planning, a Bash script for detection and webhook alerting, and GitHub Actions for automation.

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
├── README.md
├── .gitignore
├── terraform/
│   ├── main.tf
│   └── .terraform.lock.hcl
├── scripts/
│   └── detect-drift.sh
└── proof/
    ├── 01-manual-drift.png
    ├── 02-terraform-detection.png
    ├── 03-webhook-alert.png
    ├── 04-github-actions.png
    └── drift-report.txt
```

The automated workflow is located at `.github/workflows/drift-detection.yml` in the repository root.

## How It Works

1. Terraform provisions an Nginx Docker container.
2. A manual change modifies the container's restart policy outside Terraform.
3. The detector runs `terraform plan -detailed-exitcode`.
4. When changes are detected, the script saves the plan and examines its JSON representation.
5. The script sends a JSON webhook alert containing the formatted plan and resource-change count.
6. GitHub Actions automates the test and uploads available proof artifacts.

## Terraform Exit Codes

| Exit code | Meaning | Script behavior |
|---|---|---|
| `0` | No changes proposed | Reports no changes and exits successfully |
| `1` | Terraform error | Prints the error and exits unsuccessfully |
| `2` | Changes proposed | Counts changed resources and attempts webhook alerting |

A proposed change is not automatically proof of unauthorized activity. Review the plan to understand the difference.

## Local Setup

### Prerequisites

Install Docker, Terraform, Python 3, Bash, and curl.

### Initialize Terraform

```bash
cd sprint-9/terraform
terraform init
terraform validate
terraform apply
```

Review the proposed infrastructure changes before approving the apply.

### Simulate manual drift

Change the restart policy directly through Docker:

```bash
docker update --restart always sprint-9-drift-test
```

Verify the change:

```bash
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' sprint-9-drift-test
```

The expected output is `always`.

### Run the detector

From the repository root, configure the webhook URL in your shell without committing it:

```bash
export WEBHOOK_URL="YOUR_WEBHOOK_URL"
./sprint-9/scripts/detect-drift.sh
```

Replace `YOUR_WEBHOOK_URL` locally with your webhook receiver's URL. Never commit or share the actual URL.

The expected difference is:

```text
restart = "always" -> "no"
```

The script writes the formatted plan to `sprint-9/proof/drift-report.txt`.

## Webhook Alerts

The detector sends a JSON payload containing:

- Project name
- Event type
- Terraform exit code
- Number of resources with proposed changes
- Formatted plan report

An HTTP 2xx response indicates that the receiver accepted the request. Check the receiver to verify the alert contents.

For GitHub Actions, add a repository Actions secret named `WEBHOOK_URL`.

## GitHub Actions

The workflow is stored at `.github/workflows/drift-detection.yml`.

It supports manual execution and a daily schedule at 02:00 UTC (07:30 IST). Each run creates temporary test infrastructure, deliberately changes the Docker restart policy, runs drift detection, sends a webhook alert, verifies the detected difference, and uploads proof artifacts.

This workflow demonstrates the automated process. It does not continuously monitor the user's persistent WSL infrastructure.

## Proof

- `proof/01-manual-drift.png` — manual Docker change.
- `proof/02-terraform-detection.png` — detector output and webhook status.
- `proof/03-webhook-alert.png` — received webhook payload and Terraform difference.
- `proof/04-github-actions.png` — successful automated workflow run.
- `proof/drift-report.txt` — latest local Terraform plan report.

## Limitations

- The demonstration uses Docker rather than live AWS infrastructure.
- GitHub Actions creates fresh temporary infrastructure and simulates drift on each run.
- A proposed Terraform change does not independently establish whether the change was unauthorized.
- webhook.site is suitable for testing, not production alerting.
- Persistent infrastructure monitoring, remote state, and production authorization auditing are outside this demonstration's scope.
