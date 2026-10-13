# Sprint 5: Terraform State Security & Concurrent Team Workflows

## Overview

This project demonstrates remote Terraform state management, state migration, state locking, and state security configuration.

The implementation uses Terraform with LocalStack to simulate AWS S3 and DynamoDB locally. LocalStack was used with the team lead's approval instead of deploying resources to a real AWS account.

## Objectives

- Configure an S3-compatible remote Terraform backend.
- Enable server-side encryption for remote state.
- Enable bucket versioning and block public access.
- Configure DynamoDB-based state locking.
- Demonstrate migration from local state to remote state.
- Verify Terraform state and backend operations.
- Document the setup, verification steps, and limitations.

## Technologies Used

- Terraform
- Docker and Docker Compose
- LocalStack Community Edition
- AWS CLI
- Amazon S3 API
- Amazon DynamoDB API
- Bash

## Project Structure

```text
sprint-5/
├── bootstrap.sh
├── docker-compose.yml
├── README.md
├── .gitignore
├── proofs/
└── terraform/
    ├── backend.tf
    ├── main.tf
    └── env.sh
```

## Architecture

LocalStack provides local S3 and DynamoDB-compatible services.

- **Remote state:** S3 bucket `sprint5-terraform-state`
- **State key:** `sprint-5/demo/terraform.tfstate`
- **Region:** `us-east-1`
- **Encryption:** AES-256 server-side encryption
- **Versioning:** Enabled
- **Public access block:** All four settings enabled
- **Locking:** DynamoDB table `terraform-state-lock`
- **LocalStack endpoint:** `http://localhost:4566`

## Setup

### 1. Start LocalStack

From the `sprint-5` directory:

```bash
docker compose up -d
```

Check the service health:

```bash
curl -s http://localhost:4566/_localstack/health
```

S3 and DynamoDB should report as running.

### 2. Configure the backend resources

Run:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

The bootstrap script creates the bucket and DynamoDB table if they do not already exist. It also enables versioning, configures AES-256 encryption, and applies the public-access-block settings.

Existing resources are reused.

### 3. Initialize Terraform

```bash
cd terraform
source env.sh
terraform init
```

The backend is configured in `backend.tf`.

The `env.sh` file contains dummy credentials for LocalStack only. It must not contain real AWS credentials.

## State Migration

The initial migration was performed using:

```bash
terraform init -migrate-state
```

Terraform was prompted to migrate the existing local state to the configured remote backend, and the migration completed successfully.

The remote state object was subsequently verified using:

```bash
aws --endpoint-url=http://localhost:4566 s3api head-object \
  --bucket sprint5-terraform-state \
  --key sprint-5/demo/terraform.tfstate
```

The response confirmed that the object exists and reports `AES256` server-side encryption.

To inspect the resources currently recorded in state:

```bash
terraform state list
```

The migration test resource is:

```text
terraform_data.migration_test
```

Do not rerun migration casually. Back up any existing state and carefully review Terraform's migration prompt before changing backend configuration.

## Security Verification

### Encryption

```bash
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption \
  --bucket sprint5-terraform-state
```

Expected setting: `AES256`.

### Public-access blocking

```bash
aws --endpoint-url=http://localhost:4566 s3api get-public-access-block \
  --bucket sprint5-terraform-state
```

All four settings should be `true`:

- `BlockPublicAcls`
- `IgnorePublicAcls`
- `BlockPublicPolicy`
- `RestrictPublicBuckets`

### Versioning

```bash
aws --endpoint-url=http://localhost:4566 s3api get-bucket-versioning \
  --bucket sprint5-terraform-state
```

Expected status: `Enabled`.

### DynamoDB lock table

```bash
aws --endpoint-url=http://localhost:4566 dynamodb describe-table \
  --table-name terraform-state-lock \
  --query 'Table.TableStatus'
```

Expected status: `ACTIVE`.

### Terraform validation

From the `terraform` directory:

```bash
terraform fmt
terraform validate
terraform plan
```

Review the plan before applying changes.

## State Locking Demonstration

Terraform uses the configured DynamoDB table to coordinate access to the remote state.

During the temporary locking demonstration, a DynamoDB scan showed an active lock entry containing the state path, operation type, operation ID, and creation time.

The captured active-lock evidence demonstrates locking during `terraform apply`.

The assignment also requests a screenshot of the lock during an active `terraform plan`. That specific proof must be captured separately before claiming the complete screenshot requirement has been met.

## Evidence and Screenshots

The `proofs/` directory is intended to contain the following screenshots:

1. `01-remote-state-s3.png` — remote state object.
2. `02-state-encryption.png` — AES-256 encryption.
3. `03-public-access-block.png` — all four public-access settings.
4. `04-bucket-versioning.png` — enabled versioning.
5. `05-dynamodb-lock-table.png` — active table status.
6. `06-terraform-init.png` — successful backend initialization.
7. `07-state-migration.png` — original successful state migration output.
8. `08-active-state-lock-apply.png` — active DynamoDB lock during apply.
9. `09-active-state-lock-plan.png` — active DynamoDB lock during plan, once captured.

Only include screenshots that have actually been captured. Do not treat a successful `terraform init` or `terraform state list` by itself as proof that migration occurred.

## Limitations

- **Local simulation:** The project uses LocalStack Community Edition rather than a real AWS account. The S3 and DynamoDB behavior is simulated locally.
- **Production security:** The configuration demonstrates security settings, but it does not establish production-grade AWS security. A real deployment requires suitable IAM permissions, secure credential handling, and verification in the actual AWS account.
- **Credentials:** The supplied environment credentials are dummy LocalStack credentials and must never be reused as real AWS credentials.
- **Terraform warning:** Terraform 1.16.4 reports that the S3 backend's `dynamodb_table` parameter is deprecated in favor of `use_lockfile`. The current configuration retains DynamoDB locking to demonstrate the assignment's explicit requirement. The warning should be reviewed when adapting the project to a newer backend configuration.
- **Plan-lock evidence:** The captured active-lock screenshot demonstrates `apply` locking. Separate evidence of a lock during `plan` is required to satisfy the exact screenshot requirement.
- **Testing scope:** Successful local checks do not prove that the configuration has been deployed or tested in real AWS.

## Repository Hygiene

Terraform state files, backups, saved plans, local credentials, and `.terraform/` working directories must not be committed.

The `.gitignore` file excludes these local artifacts. Review `git status` before committing.

## Conclusion

Sprint 5 demonstrates remote Terraform state storage, encryption configuration, bucket versioning, public-access blocking, local-to-remote state migration, and DynamoDB-based state locking using an approved LocalStack simulation.

The project should be submitted with the evidence screenshots and the remaining plan-lock proof clearly accounted for.
