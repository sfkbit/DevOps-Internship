# Sprint 7 — Cloud-Managed Container Orchestration Infrastructure

## 1. Overview

This project uses Terraform to define infrastructure for a managed Kubernetes cluster on Amazon Web Services (AWS) using Amazon Elastic Kubernetes Service (EKS).

The project demonstrates Infrastructure as Code (IaC), custom VPC networking, IAM role separation, managed node groups, and configurable scaling.

### Key features

- Amazon EKS managed Kubernetes cluster.
- Custom VPC with two public and two private subnets.
- Networking resources distributed across two configured Availability Zones.
- Dedicated IAM roles for the EKS control plane and worker nodes.
- Two managed node groups: `general-workloads` and `spot-workloads`.
- Configurable instance types and node group scaling limits.
- Terraform outputs for cluster connection information.
- Private Kubernetes API endpoint enabled by default.
- Terraform validation, plan generation, and automated configuration tests.

**Execution status:** Terraform validation, testing, and local plan generation completed successfully. No AWS infrastructure was created because the sprint only requires successful validation and planning.

---

## 2. Tools and Technologies

| Tool or service | Purpose |
|---|---|
| Terraform | Infrastructure as Code |
| Amazon EKS | Managed Kubernetes control plane |
| Amazon VPC | Custom network architecture |
| AWS IAM | Identity and access management |
| AWS provider for Terraform | Defines AWS infrastructure resources |
| WSL Ubuntu | Local development environment |
| Git and GitHub | Version control and project submission |

---

## 3. Architecture

The Terraform configuration defines the following infrastructure:

1. A VPC with CIDR range `10.0.0.0/16`.
2. Two public subnets across two configured Availability Zones.
3. Two private subnets across the same configured Availability Zones.
4. An Internet Gateway for the public network.
5. Public and private route tables and subnet associations.
6. An EKS cluster integrated with the configured VPC subnets.
7. A dedicated IAM role for the EKS control plane.
8. A separate IAM role for EC2 worker nodes.
9. Two managed EKS node groups with different capacity strategies.

### Network addressing

| Network component | CIDR |
|---|---|
| VPC | `10.0.0.0/16` |
| Public subnet 1 | `10.0.1.0/24` |
| Public subnet 2 | `10.0.2.0/24` |
| Private subnet 1 | `10.0.11.0/24` |
| Private subnet 2 | `10.0.12.0/24` |

The Availability Zones are configured locally as `ap-south-1a` and `ap-south-1b`, avoiding a live AWS lookup during local planning.

### Kubernetes API endpoint security

The default configuration enables private endpoint access and disables public endpoint access.

Public endpoint access can be enabled through variables. When enabled, the configuration requires at least one trusted CIDR range.

A private-only endpoint improves the default network exposure posture, but it also means that clients must have suitable network connectivity to the VPC to access the Kubernetes API.

---

## 4. Managed Node Groups and Autoscaling

The configuration defines two EKS managed node groups.

| Setting | General workloads | Spot workloads |
|---|---|---|
| Node group name | `general-workloads` | `spot-workloads` |
| Capacity type | On-Demand | Spot |
| Instance types | `t3.medium` | `t3.medium`, `t3a.medium` |
| Minimum size | 2 | 0 |
| Desired size | 2 | 0 |
| Maximum size | 4 | 5 |

### General workloads

The `general-workloads` node group uses On-Demand EC2 capacity.

It is intended for applications that need more predictable instance availability. Its default configuration maintains two desired nodes, with a permitted range of two to four nodes.

### Spot workloads

The `spot-workloads` node group uses Spot EC2 capacity.

It is intended for suitable workloads that can tolerate interruptions, such as interruptible batch jobs and other fault-tolerant workloads.

Its desired and minimum sizes are initially zero, allowing the group to remain unused until configured for suitable workloads.

Spot instances may be interrupted by AWS, so workloads placed on this group must tolerate disruption.

### Important scaling limitation

The node groups define minimum, desired, and maximum capacity. These settings establish scaling boundaries, but they do not independently implement workload-driven autoscaling.

A Kubernetes node autoscaling component, such as Cluster Autoscaler or Karpenter, would need to be configured separately to adjust node capacity automatically in response to workload demand.

---

## 5. IAM Roles and Policies

The configuration separates permissions for the EKS control plane from permissions for the worker nodes.

### 5.1 EKS control-plane role

The configuration creates a dedicated IAM role trusted by the `eks.amazonaws.com` service.

Attached AWS-managed policy:

- `AmazonEKSClusterPolicy`

This role provides the permissions required by the EKS control plane to manage cluster-related AWS resources.

### 5.2 Worker-node role

The configuration creates a separate IAM role trusted by the `ec2.amazonaws.com` service.

Attached AWS-managed policies:

- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`

These policies provide common permissions needed by EKS worker nodes for cluster communication, networking, and pulling container images from Amazon ECR.

### 5.3 Workload identity

The configuration also includes optional EKS Pod Identity resources for an example workload.

These resources are disabled by default. They can be enabled through the relevant Terraform variable, with optional IAM policy JSON supplied for the example workload.

The optional configuration is intended to demonstrate a separate identity for application workloads rather than granting application permissions directly to every worker node.

**Production consideration:** IAM policies should be reviewed against current AWS recommendations. Workload-specific permissions should be narrowly scoped, and unnecessary permissions should be avoided.

---

## 6. Terraform Project Structure

```text
sprint-7/
├── providers.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── README.md
├── modules/
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── tests/
│   └── eks.tftest.hcl
└── proof/
    ├── 01-terraform-validate.png
    ├── 02-terraform-plan-resources.png
    ├── 03-terraform-plan-summary.png
    └── 04-terraform-test.png
```

The `proof/` directory is intended to contain screenshots of the actual terminal results. Ensure the filenames in the repository match the screenshots that were captured.

The `terraform.tfvars.example` file provides example configuration values. Terraform does not automatically load this file because of its `.example` suffix.

---

## 7. Configuration Variables

The project uses variables to configure important infrastructure settings, including:

- AWS region and project name.
- VPC CIDR and public/private subnet CIDRs.
- Kubernetes version.
- General and Spot node group instance types.
- Minimum, desired, and maximum node counts.
- Kubernetes API endpoint access.
- Trusted CIDR ranges for optional public endpoint access.
- Optional Pod Identity configuration.

### Default configuration

| Setting | Value |
|---|---|
| AWS region | `ap-south-1` — Mumbai |
| Kubernetes version | `1.33` |
| VPC CIDR | `10.0.0.0/16` |
| Private API endpoint | Enabled |
| Public API endpoint | Disabled |
| Pod Identity example | Disabled |

These are the configuration values used for the local plan. Before a real deployment, the selected Kubernetes version and resource compatibility must be verified against the target AWS region.

---

## 8. Terraform Outputs

The configuration defines outputs for:

- EKS cluster name.
- Cluster API endpoint.
- Cluster certificate authority data.
- AWS CLI command for configuring `kubectl`.
- VPC ID.
- Private subnet IDs.

The cluster endpoint and certificate authority values are generated by AWS when the cluster is actually created. Because this project was not applied to AWS, the local plan does not provide real deployed-cluster connection details.

---

## 9. Validation, Testing, and Planning

The following commands were used to check the configuration without creating AWS infrastructure.

### Step 1: Format the Terraform files

```bash
terraform fmt -recursive
```

This formats Terraform configuration files consistently.

### Step 2: Initialize Terraform

```bash
terraform init
```

This initializes the working directory and downloads the required provider and module dependencies.

### Step 3: Validate the configuration

```bash
terraform validate
```

**Observed result:**

```text
Success! The configuration is valid.
```

### Step 4: Run Terraform tests

```bash
terraform test -verbose
```

**Observed result:**

```text
Success! 1 passed, 0 failed.
```

The test checks selected configuration expectations, including the cluster configuration and node group settings.

This is a configuration-level test, not proof that AWS will successfully create the infrastructure.

### Step 5: Generate the Terraform plan

```bash
terraform plan -refresh=false
```

The plan completed successfully using dummy AWS credentials and provider validation settings. The configured Availability Zones were supplied locally rather than retrieved from AWS.

**Observed plan summary:**

```text
Plan: 22 to add, 0 to change, 0 to destroy.
```

The plan describes the resources Terraform intends to create, including the EKS cluster, node groups, IAM resources, VPC, subnets, Internet Gateway, route tables, and route table associations.

The exact plan may change if the configuration or provider versions change.

### Optional: Save plan output as text

```bash
terraform plan -refresh=false -no-color > plan-proof.txt 2>&1
```

This saves the plan output for reference and for capturing readable proof screenshots.

The plan can be reviewed using commands such as:

```bash
head -n 35 plan-proof.txt
tail -n 35 plan-proof.txt
```

**Important:** `terraform plan` previews proposed changes. It does not create the infrastructure.

---

## 10. Limitations Encountered and What We Did Instead

The project was deliberately completed without deploying a live EKS cluster. The following limitations and alternatives are documented for transparency.

### 10.1 No live AWS deployment

**Limitation:** A real EKS cluster requires AWS account access, suitable permissions, and billable infrastructure. The task explicitly states that validation and planning are sufficient.

**What we did instead:** We configured the AWS provider with dummy credentials and generated a local Terraform plan. We ran validation and Terraform tests without executing `terraform apply`.

**Impact:** The project demonstrates the intended infrastructure configuration, but it does not prove that the resources were successfully created in AWS.

### 10.2 No live AWS credential or account verification

**Limitation:** Dummy credentials cannot authenticate to AWS or verify actual account permissions.

**What we did instead:** The provider configuration skips selected credential, metadata, account-ID, and region validation checks so the configuration can be planned locally.

**Impact:** The plan cannot confirm AWS authentication, IAM permissions, account quotas, service availability, or successful deployment.

### 10.3 Availability Zones are configured locally

**Limitation:** Without querying AWS, the configuration cannot confirm the live availability of the selected Availability Zones in the target account and region.

**What we did instead:** We configured `ap-south-1a` and `ap-south-1b` directly in Terraform rather than using a live AWS Availability Zone data source.

**Impact:** The configuration can be planned locally, but the selected zones must be checked before deployment.

### 10.4 No `terraform apply`

**Limitation:** Because the infrastructure was not applied, there is no live cluster to connect to, no actual EKS endpoint or certificate returned by AWS, and no running worker nodes to verify.

**What we did instead:** We used `terraform validate`, `terraform test -verbose`, and `terraform plan -refresh=false` as the sprint's verification steps.

**Impact:** The work satisfies the requested local validation and planning workflow. Live provisioning, connectivity, and runtime behavior remain unverified.

### 10.5 No NAT gateway or private-subnet egress infrastructure

**Limitation:** The configuration does not include a NAT gateway for private subnet internet egress. A private node group may require a suitable egress path or appropriate VPC endpoints to download images, access required AWS services, and reach external services.

**What we did instead:** We kept the networking design focused on the requested VPC, public/private subnet layout, Internet Gateway, and routing resources, avoiding the additional cost of a NAT gateway during a future deployment.

**Impact:** The networking configuration requires further review before deploying private worker nodes. The absence of a NAT gateway is not a guarantee of zero AWS cost if the infrastructure is eventually applied.

### 10.6 Autoscaling is configured but not runtime-tested

**Limitation:** The node groups specify minimum, desired, and maximum sizes, but the project does not demonstrate a running Kubernetes node autoscaler responding to actual workload demand.

**What we did instead:** We defined configurable scaling settings for both managed node groups in Terraform.

**Impact:** The capacity boundaries are defined, but automatic workload-driven scaling requires a separately configured and tested component such as Cluster Autoscaler or Karpenter.

### 10.7 Pod Identity is optional

**Limitation:** The optional Pod Identity resources are disabled by default, so the successful default plan does not verify their live behavior.

**What we did instead:** We included optional Terraform resources and variables to demonstrate the intended workload identity configuration without requiring those resources in the default plan.

**Impact:** The optional configuration must be reviewed and tested against the target AWS provider and EKS environment before use.

### 10.8 No live AWS integration tests

**Limitation:** Local validation and plan generation cannot verify the actual behavior of EKS, worker nodes, IAM permissions, Kubernetes API access, or AWS service integration.

**What we did instead:** We ran Terraform configuration tests and inspected the planned infrastructure.

**Impact:** The tests provide configuration-level evidence, not end-to-end integration or production acceptance testing.

---

## 11. Production-Readiness Improvements

Before deploying this configuration in a real AWS account, the following work should be considered:

- Verify Kubernetes version support and compatibility in the selected AWS region.
- Review IAM policies and reduce permissions where appropriate.
- Confirm subnet, routing, and private worker-node egress requirements.
- Decide whether the Kubernetes API endpoint should remain private or allow restricted public access.
- Configure and test a Kubernetes node autoscaler if workload-driven scaling is required.
- Validate optional Pod Identity resources against the target environment.
- Review EKS control-plane logging, monitoring, encryption, and upgrade requirements.
- Establish an appropriate state backend, access controls, and state protection.
- Test deployment and connectivity using an authorized AWS account before production use.
- Estimate and approve AWS costs before provisioning resources.

These are further deployment and production-hardening steps; they are not claimed as completed or verified by this sprint's local plan.

---

## 12. Proof of Work

The submission should include genuine terminal screenshots showing:

1. Successful `terraform validate`.
2. The Terraform plan's resource details.
3. The final plan summary showing the proposed resource changes.
4. Successful `terraform test -verbose`.

The screenshots should show actual command output and should be readable. Multiple screenshots may be used for the long Terraform plan.

The plan summary recorded during this run was:

```text
Plan: 22 to add, 0 to change, 0 to destroy.
```

The configuration was validated and planned locally. No AWS infrastructure was created.

---

## 13. Conclusion

Sprint 7 implements a Terraform configuration for an AWS EKS managed Kubernetes cluster with custom VPC networking, dedicated IAM roles, two managed node groups, configurable capacity limits, security settings, and cluster outputs.

The recorded checks completed successfully:

- `terraform validate` — successful.
- `terraform test -verbose` — 1 passed, 0 failed.
- `terraform plan -refresh=false` — 22 to add, 0 to change, 0 to destroy.

The implementation was intentionally planned locally using dummy AWS credentials to avoid deploying billable cloud infrastructure. The limitations of this approach, the alternatives used, and the additional work required before a real deployment are documented above.

This submission demonstrates the requested infrastructure configuration and Terraform planning workflow without claiming that a live EKS cluster was provisioned or tested.
