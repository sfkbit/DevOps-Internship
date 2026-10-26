# Sprint 8: Automated Disaster Recovery & Cloud Lifecycle Management

## Overview

This project automates AWS EBS snapshot backups and removes expired snapshots to manage the backup lifecycle.

The solution uses Python and Boto3 for the backup logic and Terraform to define the AWS infrastructure.

Since an AWS account was not available, Terraform was validated and planned locally, and the backup logic was tested using mocked AWS responses.

## Features

- Finds EBS volumes tagged `Backup=true`.
- Creates snapshots of matching volumes.
- Tags snapshots with `ManagedBy=sprint-8` and `CreationTimestamp`.
- Identifies snapshots managed by this project.
- Deletes managed snapshots older than seven days.
- Logs snapshot creation, deletion, and job completion.
- Uses Terraform to configure the Lambda function and scheduled execution.

## Project Structure

```text
sprint-8/
├── lambda/
│   ├── backup.py
│   └── requirements.txt
├── tests/
│   └── test_backup.py
├── scripts/
├── terraform/
│   └── main.tf
├── proof/
│   ├── execution-logs.txt
│   └── terraform-plan.txt
└── README.md
```

## How It Works

1. Amazon EventBridge triggers the Lambda function daily at 02:00 UTC.
2. Lambda searches for EBS volumes tagged `Backup=true`.
3. A snapshot is created for each matching volume.
4. Each new snapshot receives a project tag and creation timestamp.
5. The function lists snapshots tagged `ManagedBy=sprint-8`.
6. Snapshots older than seven days are deleted.
7. The function prints logs describing the actions performed.

## Schedule

The EventBridge schedule configured in Terraform is:

`cron(0 2 * * ? *)`

This runs every day at **02:00 UTC (07:30 AM IST)**.

## Snapshot Retention Policy

The retention period is seven days.

The function calculates a cutoff time using the current UTC time minus seven days. It compares each managed snapshot's AWS `StartTime` against this cutoff and deletes snapshots older than the retention period.

Only snapshots tagged `ManagedBy=sprint-8` are considered for deletion. This helps prevent the function from deleting snapshots managed by other systems.

## IAM Permissions

Terraform creates an IAM execution role for the Lambda function.

| Permission | Purpose |
|---|---|
| `ec2:DescribeVolumes` | Find volumes requiring backups |
| `ec2:DescribeSnapshots` | Find managed snapshots |
| `ec2:CreateSnapshot` | Create EBS snapshots |
| `ec2:CreateTags` | Tag new snapshots |
| `ec2:DeleteSnapshot` | Delete expired snapshots |
| `logs:CreateLogGroup` | Create a CloudWatch log group |
| `logs:CreateLogStream` | Create log streams |
| `logs:PutLogEvents` | Write execution logs |

**Security note:** The current Terraform policy uses `Resource = "*"` for these permissions. Some EC2 operations require wildcard resource scope. For production use, restrict permissions to supported resources and review the policy against AWS IAM requirements.

## Terraform Resources

The Terraform configuration defines:

- Lambda execution IAM role
- IAM permissions policy
- AWS Lambda function
- CloudWatch EventBridge schedule
- EventBridge target for Lambda
- Lambda permission allowing EventBridge to invoke the function

## Local Testing and Validation

Activate the Python virtual environment:

```bash
source venv/bin/activate
```

Run the unit tests:

```bash
python3 -m unittest discover -s tests -v
```

The tests use mocked Boto3 responses and check:

- Snapshot creation and tagging
- Deletion of expired snapshots
- Handling of an empty volume list

Validate the Terraform configuration:

```bash
terraform -chdir=terraform validate
```

Generate a Terraform plan:

```bash
terraform -chdir=terraform plan
```

Save the plan output:

```bash
terraform -chdir=terraform plan 2>&1 | tee proof/terraform-plan.txt
```

Save the test output:

```bash
python3 -m unittest discover -s tests -v 2>&1 | tee proof/execution-logs.txt
```

## Proof of Execution

The `proof/` directory contains:

- `terraform-plan.txt` — saved Terraform plan output.
- `execution-logs.txt` — saved unit test output, including mocked snapshot creation and deletion messages.

These files demonstrate local Terraform planning and mocked test execution. They do not represent a live AWS deployment.

## Limitations

- No AWS account was available for live deployment.
- Snapshot operations were tested with mocks, not real EBS volumes.
- The Terraform provider uses placeholder credentials for local planning.
- A real deployment requires an AWS account, appropriate permissions, and deployment configuration.
- Production use should include robust error handling, monitoring, and a review of IAM permissions.

**Important:** Do not run `terraform apply` expecting this local configuration to deploy successfully to AWS. The current setup is intended for local validation and planning.

## Summary

Sprint 8 demonstrates infrastructure automation using Terraform, a Python/Boto3 backup workflow, scheduled execution, snapshot retention, IAM permissions, and local unit testing.
