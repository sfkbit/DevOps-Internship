# Sprint 1 - Terraform Network Provisioning

## Overview

This project implements a VPC-style network architecture using Terraform and Docker.

The original Sprint 1 assignment is based on provisioning a VPC with public and private subnets using AWS or GCP. For this implementation, the same network structure is created locally using Docker, with Terraform used to provision and manage the infrastructure.

The main network address space used is `10.0.0.0/16`.

The project contains:

- 2 public networks
- 2 private networks
- Configurable CIDR values
- Terraform outputs for the created networks
- Internet connectivity for the public networks
- External network isolation for the private networks

## Network Configuration

### Public Networks

**Public Network 1**

Name: `sprint-1-public-1`

CIDR: `10.0.1.0/24`

**Public Network 2**

Name: `sprint-1-public-2`

CIDR: `10.0.2.0/24`

Both public networks use Docker bridge networking and have external connectivity.

### Private Networks

**Private Network 1**

Name: `sprint-1-private-1`

CIDR: `10.0.3.0/24`

**Private Network 2**

Name: `sprint-1-private-2`

CIDR: `10.0.4.0/24`

Both private networks use Docker's `internal` mode and do not have external internet access.

## Local Implementation

The original assignment uses cloud-specific resources such as VPCs, subnets, Internet Gateways, route tables and Availability Zones.

Since this project is implemented locally, these concepts are mapped to Docker networking where applicable.

- VPC address space: `10.0.0.0/16`
- Public subnets: Docker bridge networks
- Private subnets: Docker internal networks
- Public internet connectivity: Docker networking and NAT
- Internet Gateway and routing: Docker networking mechanism
- Availability Zones: Not applicable to the local environment

This is a local adaptation of the requested network architecture and is not an AWS or GCP deployment.

## Project Structure

```text
sprint-1/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── README.md
└── proof/
    ├── 01-terraform-validate.png
    ├── 02-terraform-plan.png
    ├── 03-terraform-output.png
    ├── 04-network-configuration.png
    ├── 05-public-connectivity.png
    └── 06-private-isolation.png
```

## Terraform Files

### `main.tf`

Contains the Docker provider configuration and the four Docker network resources.

### `variables.tf`

Contains the configurable CIDR values and project name.

### `outputs.tf`

Provides the network IDs, network names and parent network CIDR.

### `terraform.tfvars.example`

Contains example values for the Terraform variables.

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

Go to the project directory:

```bash
cd ~/DevOps-Internship/sprint-1
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

Apply the configuration:

```bash
terraform apply
```

View the Terraform outputs:

```bash
terraform output
```

## Testing

### Check the Networks

The created networks can be inspected using:

```bash
docker network inspect sprint-1-public-1
```

The same command can be used for the other networks:

```text
sprint-1-public-2
sprint-1-private-1
sprint-1-private-2
```

The public networks should show `Internal: false`.

The private networks should show `Internal: true`.

### Test Public Connectivity

A temporary Alpine container can be used to test internet connectivity from a public network:

```bash
docker run --rm --network sprint-1-public-1 alpine ping -c 3 8.8.8.8
```

Successful replies confirm that the public network has external connectivity.

### Test Private Network Isolation

The private network can be tested using:

```bash
docker run --rm --network sprint-1-private-1 alpine ping -c 3 8.8.8.8
```

The expected result is a network-unreachable error, confirming that the private network does not have external internet access.

## Proof of Work

The `proof` directory contains screenshots of the main validation and testing steps.

### Terraform Validation

`01-terraform-validate.png`

Shows that the Terraform configuration is valid.

### Terraform Plan

`02-terraform-plan.png`

Shows that Terraform found no differences between the configuration and the existing infrastructure.

### Terraform Outputs

`03-terraform-output.png`

Shows the configured parent CIDR and the created public and private networks.

### Network Configuration

`04-network-configuration.png`

Shows the configuration of the four Docker networks, including their CIDRs, gateways and public/private settings.

### Public Connectivity

`05-public-connectivity.png`

Shows successful internet connectivity from the public network.

### Private Network Isolation

`06-private-isolation.png`

Shows that the private network cannot reach the external internet.

## Cleanup

To remove the networks created by Terraform:

```bash
terraform destroy
```
