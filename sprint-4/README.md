# Sprint 4 - Database Infrastructure & Automated Storage Management

## Overview

This project uses Terraform to configure an AWS RDS PostgreSQL database with security controls, automated backups, and storage autoscaling.

The main objective of Sprint 4 is to define database infrastructure using Terraform and follow Infrastructure as Code (IaC) practices.

AWS account access was unavailable, so the project was validated and a Terraform plan was generated without applying or creating any AWS resources.

The project includes:

- PostgreSQL RDS database configuration
- Database subnet group
- Security group configuration
- Sensitive database password variable
- Automated backups and maintenance window
- Storage autoscaling
- Terraform validation and plan output

---

## Architecture

The project defines the following AWS database architecture:

~~~text
        Application Subnet
                |
                | PostgreSQL - Port 5432
                |
                v
        Database Security Group
                |
                v
        Private Database Subnets
                |
                v
        AWS RDS PostgreSQL
                |
        +-------+-------+
        |               |
    Backups        Storage Autoscaling
~~~

The database is configured to be privately accessible and to allow PostgreSQL traffic only from the specified application subnet.

**Note:** This represents the intended architecture. The VPC and subnet IDs in the current configuration are placeholders.

---

## Project Structure

~~~text
sprint-4/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── .gitignore
├── modules/
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── proof/
    ├── terraform-plan.txt
    └── 01-terraform-validate.png
~~~

---

## Requirements

The following tools are required:

- Ubuntu / WSL
- Terraform CLI
- Internet connection to download the Terraform AWS provider

An AWS account is required for actual deployment, but it was not available for this sprint.

---

## Database Configuration

The database module is located in:

~~~text
modules/database/
~~~

It defines the following AWS resources:

- `aws_db_instance` - PostgreSQL database
- `aws_db_subnet_group` - Database subnet configuration
- `aws_security_group` - Database access rules

The database uses the following configuration:

| Setting | Value |
|---|---|
| Database engine | PostgreSQL |
| Instance class | `db.t3.micro` |
| Initial storage | 20 GB |
| Maximum storage | 100 GB |
| Database port | 5432 |
| Backup retention | 7 days |
| Public access | Disabled |

---

## Security Group

The database security group allows inbound PostgreSQL traffic only from the configured application subnet.

~~~text
Protocol: TCP
Port: 5432
Source: Application subnet CIDR
~~~

No unrestricted inbound database rule is configured.

The database is also configured with `publicly_accessible = false`.

---

## Backups and Storage Autoscaling

The database configuration includes:

- Automated backup retention of 7 days
- Backup window
- Weekly maintenance window
- Initial storage of 20 GB
- Maximum autoscaled storage of 100 GB

These settings define the intended RDS configuration. Their operation has not been tested against a live AWS database.

---

## Input Variables

The root `variables.tf` file defines the main configuration values.

| Variable | Purpose |
|---|---|
| `aws_region` | AWS region |
| `db_name` | Database name |
| `db_username` | Database username |
| `db_password` | Database password |
| `vpc_id` | VPC containing the database |
| `db_subnet_ids` | Private database subnet IDs |
| `app_subnet_cidr` | Application subnet allowed to connect |
| `allocated_storage` | Initial database storage |
| `max_allocated_storage` | Maximum database storage |
| `backup_retention` | Backup retention period |
| `maintenance_window` | Weekly maintenance window |

The database password variable is marked as sensitive.

---

## Output Variables

The project defines the following outputs:

- Database endpoint
- Database port
- Database security group ID
- Database subnet group name

These outputs are intended to provide useful database information after deployment.

Since no AWS resources were created, the actual database endpoint and generated resource IDs are unavailable.

---

## Terraform Configuration

### Initialize Terraform

Run the following command from the Sprint 4 directory:

~~~bash
terraform init
~~~

This initializes Terraform and downloads the required AWS provider.

### Validate the Configuration

~~~bash
terraform validate
~~~

The configuration validation completed successfully.

Expected output:

~~~text
Success! The configuration is valid.
~~~

### Generate Terraform Plan

Because AWS account access was unavailable, the plan was generated using temporary dummy credentials and with resource refresh disabled.

~~~bash
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_EC2_METADATA_DISABLED=true terraform plan -refresh=false
~~~

The command generated a plan showing:

~~~text
Plan: 3 to add, 0 to change, 0 to destroy.
~~~

The three planned resources are:

- PostgreSQL RDS database
- Database subnet group
- Database security group

The dummy credentials do not provide AWS access. The `-refresh=false` option prevents Terraform from refreshing existing AWS resources during this planning operation.

**No `terraform apply` command was executed, and no AWS resources were created.**

The VPC and subnet IDs are placeholders, so the plan does not confirm that they exist or that the resources could be deployed successfully.

---

## Proof of Work

The `proof` directory contains the following evidence:

### Terraform Plan

`terraform-plan.txt`

Contains the saved Terraform plan execution log, including the planned database, subnet group, security group, and plan summary.

### Terraform Validation

`01-terraform-validate.png`

Shows the terminal output from the successful Terraform validation.

---

## Security Considerations

- The database password variable is marked as sensitive.
- The local `terraform.tfvars` file is excluded from Git using `.gitignore`.
- Terraform state files are excluded from Git.
- The database is configured with public access disabled.
- Inbound database access is restricted to the configured application subnet.
- Real credentials and passwords should not be committed to the repository.

Marking a variable as sensitive helps hide its value in normal Terraform output, but does not automatically encrypt every copy of that value in Terraform state.

---

## Limitations

This project was not deployed to a real AWS environment because AWS account access was unavailable.

The VPC and subnet IDs are placeholders. The Terraform plan demonstrates the proposed configuration but does not verify the existence of those network resources or guarantee that deployment would succeed.

The project follows the plan-only approach permitted in the Sprint 4 task email.

---

## Sprint Status

Sprint 4 focuses on Database Infrastructure and Automated Storage Management using Terraform.

The project includes:

- PostgreSQL RDS configuration
- Database subnet group
- Security group isolation
- Sensitive password variable
- Automated backup and maintenance settings
- Storage autoscaling configuration
- Successful Terraform validation
- Terraform plan execution log

The source code, documentation, and proof of work are organized under the `sprint-4` directory.

