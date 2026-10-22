variable "aws_region" {
  description = "AWS region for the EKS cluster"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix for project resources"
  type        = string
  default     = "sprint7-eks"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR ranges for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR ranges for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.33"
}

variable "general_instance_types" {
  description = "Instance types for general workloads"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "general_min_size" {
  description = "Minimum general worker nodes"
  type        = number
  default     = 2
}

variable "general_desired_size" {
  description = "Desired general worker nodes"
  type        = number
  default     = 2
}

variable "general_max_size" {
  description = "Maximum general worker nodes"
  type        = number
  default     = 4
}

variable "spot_instance_types" {
  description = "Instance types for Spot workloads"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "spot_min_size" {
  description = "Minimum Spot worker nodes"
  type        = number
  default     = 0
}

variable "spot_desired_size" {
  description = "Desired Spot worker nodes"
  type        = number
  default     = 0
}

variable "spot_max_size" {
  description = "Maximum Spot worker nodes"
  type        = number
  default     = 5
}

variable "eks_endpoint_private_access" {
  description = "Allow Kubernetes API access from within the VPC"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Allow Kubernetes API access from the public internet"
  type        = bool
  default     = false
}

variable "eks_endpoint_public_access_cidrs" {
  description = "Trusted IPv4 CIDR ranges allowed to access the public Kubernetes API endpoint"
  type        = list(string)
  default     = []

  validation {
    condition     = !var.eks_endpoint_public_access || length(var.eks_endpoint_public_access_cidrs) > 0
    error_message = "Provide at least one trusted CIDR when public EKS endpoint access is enabled."
  }
}

variable "enable_pod_identity_example" {
  description = "Create optional EKS Pod Identity resources for an example workload"
  type        = bool
  default     = false
}

variable "pod_identity_namespace" {
  description = "Kubernetes namespace for the example workload identity"
  type        = string
  default     = "default"
}

variable "pod_identity_service_account" {
  description = "Kubernetes service account for the example workload identity"
  type        = string
  default     = "example-app"
}

variable "pod_identity_policy_json" {
  description = "Optional IAM permissions for the example workload"
  type        = string
  default     = ""

  validation {
    condition = (
      var.pod_identity_policy_json == "" ||
      can(jsondecode(var.pod_identity_policy_json))
    )
    error_message = "pod_identity_policy_json must be empty or contain valid JSON."
  }
}
