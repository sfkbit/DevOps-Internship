# Sprint 2 - Multi-Environment Terraform

## Overview

This project implements a multi-environment infrastructure setup using Terraform and Docker.

The main objective of Sprint 2 is to manage separate **Development, Staging and Production environments** using reusable Terraform infrastructure and environment-specific configuration.

The same Terraform network module is reused across all three environments, while each environment has its own network CIDRs, gateway addresses and resource size configuration.

The project contains:

- Development environment
- Staging environment
- Production environment
- Reusable Terraform network module
- Environment-specific variables
- Environment-specific Terraform configuration
- Separate network CIDR ranges
- Terraform outputs for created networks
- Terraform validation and planning for each environment

## Environment Configuration

### Development

Environment: `dev`

Resource size: `small`

Network address space: `10.10.0.0/16`

Public networks:

- `10.10.1.0/24`
- `10.10.2.0/24`

Private networks:

- `10.10.3.0/24`
- `10.10.4.0/24`

### Staging

Environment: `staging`

Resource size: `medium`

Network address space: `10.20.0.0/16`

Public networks:

- `10.20.1.0/24`
- `10.20.2.0/24`

Private networks:

- `10.20.3.0/24`
- `10.20.4.0/24`

### Production

Environment: `prod`

Resource size: `large`

Network address space: `10.30.0.0/16`

Public networks:

- `10.30.1.0/24`
- `10.30.2.0/24`

Private networks:

- `10.30.3.0/24`
- `10.30.4.0/24`

## Reusable Module

The common network infrastructure is implemented as a reusable Terraform module.

The module creates:

- 2 public Docker networks
- 2 private Docker networks
- Configurable subnet CIDRs
- Configurable gateway addresses
- Environment-specific network names

The same module is used by all three environments.

```text
                    Network Module
                         |
             +-----------+-----------+
             |           |           |
            DEV       STAGING       PROD
             |           |           |
        10.10.x.x    10.20.x.x    10.30.x.x
```

This allows the infrastructure logic to be maintained in one place while each environment uses its own configuration.

## Local Implementation

The original Sprint 2 infrastructure can be implemented using a cloud provider.

For this implementation, Terraform is used with the Docker provider to provision and test the infrastructure locally.

The environments are represented using separate Docker networks.

Each environment contains:

- 2 public networks
- 2 private networks

Private networks use Docker's `internal` mode to prevent external connectivity.

This implementation provides a local demonstration of multi-environment Terraform infrastructure without requiring an AWS or GCP account.

## Project Structure

```text
sprint-2/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   │
│   ├── staging/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   │
│   └── prod/
│       ├── main.tf
│       ├── outputs.tf
│       ├── variables.tf
│       └── terraform.tfvars
│
├── modules/
│   └── network/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
│
├── proof/
│   ├── 01-dev-plan.png
│   ├── 02-staging-plan.png
│   ├── 03-prod-plan.png
│   ├── 04-dev-configuration.png
│   ├── 05-staging-configuration.png
│   └── 06-prod-configuration.png
│
└── README.md
```

## Terraform Files

### `modules/network/main.tf`

Contains the reusable Docker network resources used by all environments.

The module creates two public networks and two private networks.

### `modules/network/variables.tf`

Contains the variables required by the network module, including:

- Environment name
- Public subnet CIDRs
- Private subnet CIDRs
- Public gateway addresses
- Private gateway addresses
- Resource size

### `modules/network/outputs.tf`

Provides information about the networks created by the module, including network names and network IDs.

### Environment `main.tf`

Each environment calls the reusable network module and passes its environment-specific configuration.

### Environment `variables.tf`

Contains the variables required by the environment configuration.

### `terraform.tfvars`

Contains environment-specific values such as:

- Environment name
- Resource size
- Public subnet CIDRs
- Private subnet CIDRs
- Public gateways
- Private gateways

## Requirements

The following are required:

- Ubuntu / WSL
- Docker
- Terraform

Check the installed versions:

```bash
docker --version
terraform --version
```

## Setup

Navigate to the required environment.

For example, Development:

```bash
cd ~/DevOps-Internship/sprint-2/environments/dev
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Create and review the Terraform plan:

```bash
terraform plan
```

The same process can be followed for the Staging and Production environments.

## Development

Navigate to the Development environment:

```bash
cd ~/DevOps-Internship/sprint-2/environments/dev
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Generate the execution plan:

```bash
terraform plan
```

The Development environment uses:

```text
Environment: dev
Resource size: small
Network range: 10.10.0.0/16
```

## Staging

Navigate to the Staging environment:

```bash
cd ~/DevOps-Internship/sprint-2/environments/staging
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Generate the execution plan:

```bash
terraform plan
```

The Staging environment uses:

```text
Environment: staging
Resource size: medium
Network range: 10.20.0.0/16
```

## Production

Navigate to the Production environment:

```bash
cd ~/DevOps-Internship/sprint-2/environments/prod
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Generate the execution plan:

```bash
terraform plan
```

The Production environment uses:

```text
Environment: prod
Resource size: large
Network range: 10.30.0.0/16
```

## Testing

### Terraform Validation

Each environment is validated using:

```bash
terraform validate
```

A successful validation returns:

```text
Success! The configuration is valid.
```

### Terraform Plan

The infrastructure changes can be reviewed using:

```bash
terraform plan
```

Each environment produces a separate Terraform plan.

The expected result for each environment is:

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

The four resources represent:

```text
1. Public Network 1
2. Public Network 2
3. Private Network 1
4. Private Network 2
```

### Docker Network Verification

Created Docker networks can be listed using:

```bash
docker network ls
```

Individual networks can be inspected using:

```bash
docker network inspect <network-name>
```

For example:

```bash
docker network inspect dev-public-1
```

Private networks can be identified by their Docker `internal` configuration.

## Environment Separation

Each environment uses its own network address space and configuration.

```text
Development
10.10.0.0/16
     |
     +-- Public 1: 10.10.1.0/24
     +-- Public 2: 10.10.2.0/24
     +-- Private 1: 10.10.3.0/24
     +-- Private 2: 10.10.4.0/24


Staging
10.20.0.0/16
     |
     +-- Public 1: 10.20.1.0/24
     +-- Public 2: 10.20.2.0/24
     +-- Private 1: 10.20.3.0/24
     +-- Private 2: 10.20.4.0/24


Production
10.30.0.0/16
     |
     +-- Public 1: 10.30.1.0/24
     +-- Public 2: 10.30.2.0/24
     +-- Private 1: 10.30.3.0/24
     +-- Private 2: 10.30.4.0/24
```

The environments are isolated from each other by using separate network ranges and separate Terraform configurations.

## Proof of Work

The `proof` directory contains screenshots demonstrating the Terraform configuration and planning results for all three environments.

### Development Plan

`01-dev-plan.png`

Shows successful Terraform validation and the execution plan for the Development environment.

### Staging Plan

`02-staging-plan.png`

Shows successful Terraform validation and the execution plan for the Staging environment.

### Production Plan

`03-prod-plan.png`

Shows successful Terraform validation and the execution plan for the Production environment.

### Development Configuration

`04-dev-configuration.png`

Shows the environment-specific Terraform configuration for Development, including the `dev` environment, `small` resource profile and `10.10.x.x` network ranges.

### Staging Configuration

`05-staging-configuration.png`

Shows the environment-specific Terraform configuration for Staging, including the `staging` environment, `medium` resource profile and `10.20.x.x` network ranges.

### Production Configuration

`06-prod-configuration.png`

Shows the environment-specific Terraform configuration for Production, including the `prod` environment, `large` resource profile and `10.30.x.x` network ranges.

## Key Concepts Covered

This sprint covers:

- Infrastructure as Code
- Terraform modules
- Reusable infrastructure
- Terraform variables
- `.tfvars` configuration
- Module inputs and outputs
- Environment separation
- Infrastructure isolation
- Terraform providers
- Terraform validation
- Terraform planning
- Local infrastructure provisioning using Docker

## Cleanup

If the infrastructure has been created using `terraform apply`, it can be removed from the selected environment using:

```bash
terraform destroy
```

Run the command from the environment directory whose infrastructure should be removed.

## Sprint Status

**Completed**

Development, Staging and Production environments have been configured using reusable Terraform infrastructure and environment-specific configuration.

All three environments have been successfully validated and Terraform execution plans have been generated successfully.
