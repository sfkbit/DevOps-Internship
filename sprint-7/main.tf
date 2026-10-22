
locals {
  availability_zones = ["ap-south-1a", "ap-south-1b"]
}

# --------------------------------------------------
# VPC MODULE
# --------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.availability_zones
}

# --------------------------------------------------
# EKS CLUSTER IAM ROLE
# --------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --------------------------------------------------
# WORKER NODE IAM ROLE
# --------------------------------------------------

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_cni_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "worker_ecr_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# --------------------------------------------------
# EKS CLUSTER
# --------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.project_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = concat(
      module.vpc.public_subnet_ids,
      module.vpc.private_subnet_ids
    )

    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
    public_access_cidrs     = var.eks_endpoint_public_access_cidrs
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Project = var.project_name
  }
}

# --------------------------------------------------
# GENERAL ON-DEMAND NODE GROUP
# --------------------------------------------------

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "general-workloads"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = var.general_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    min_size     = var.general_min_size
    desired_size = var.general_desired_size
    max_size     = var.general_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.worker_cni_policy,
    aws_iam_role_policy_attachment.worker_ecr_policy
  ]

  tags = {
    Workload = "general"
  }
}

# --------------------------------------------------
# SPOT NODE GROUP
# --------------------------------------------------

resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "spot-workloads"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = var.spot_instance_types
  capacity_type   = "SPOT"

  scaling_config {
    min_size     = var.spot_min_size
    desired_size = var.spot_desired_size
    max_size     = var.spot_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.worker_cni_policy,
    aws_iam_role_policy_attachment.worker_ecr_policy
  ]

  tags = {
    Workload = "spot"
  }
}

# --------------------------------------------------
# OPTIONAL POD IDENTITY ROLE
# Disabled by default.
# --------------------------------------------------

resource "aws_iam_role" "pod_identity" {
  count = var.enable_pod_identity_example ? 1 : 0

  name = "${var.project_name}-pod-identity-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

# Attach a workload policy only when explicitly provided.
resource "aws_iam_role_policy" "pod_identity" {
  count = (
    var.enable_pod_identity_example &&
    var.pod_identity_policy_json != ""
  ) ? 1 : 0

  name   = "${var.project_name}-pod-identity-policy"
  role   = aws_iam_role.pod_identity[0].id
  policy = var.pod_identity_policy_json
}

# --------------------------------------------------
# OPTIONAL POD IDENTITY AGENT ADD-ON
# --------------------------------------------------

resource "aws_eks_addon" "pod_identity_agent" {
  count = var.enable_pod_identity_example ? 1 : 0

  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [
    aws_eks_cluster.main
  ]
}

# --------------------------------------------------
# OPTIONAL POD IDENTITY ASSOCIATION
# --------------------------------------------------

resource "aws_eks_pod_identity_association" "example" {
  count = var.enable_pod_identity_example ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  namespace       = var.pod_identity_namespace
  service_account = var.pod_identity_service_account
  role_arn        = aws_iam_role.pod_identity[0].arn

  depends_on = [
    aws_eks_addon.pod_identity_agent
  ]
}
