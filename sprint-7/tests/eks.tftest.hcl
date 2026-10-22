run "eks_infrastructure_security_plan" {
  command = plan

  assert {
    condition     = aws_eks_cluster.main.name == var.project_name
    error_message = "EKS cluster name does not match the project name."
  }

  assert {
    condition     = aws_eks_cluster.main.version == var.kubernetes_version
    error_message = "EKS Kubernetes version does not match the configured version."
  }

  assert {
    condition     = aws_eks_node_group.general.node_group_name == "general-workloads"
    error_message = "General node group is not configured correctly."
  }

  assert {
    condition     = aws_eks_node_group.spot.node_group_name == "spot-workloads"
    error_message = "Spot node group is not configured correctly."
  }

  assert {
    condition     = aws_eks_node_group.general.capacity_type == "ON_DEMAND"
    error_message = "General node group must use On-Demand capacity."
  }

  assert {
    condition     = aws_eks_node_group.spot.capacity_type == "SPOT"
    error_message = "Spot node group must use Spot capacity."
  }

  assert {
    condition     = aws_eks_cluster.main.vpc_config[0].endpoint_private_access
    error_message = "Private Kubernetes API endpoint access must be enabled."
  }

  assert {
    condition     = !aws_eks_cluster.main.vpc_config[0].endpoint_public_access
    error_message = "Public Kubernetes API access must be disabled by default."
  }

  assert {
    condition     = var.enable_pod_identity_example == false
    error_message = "Optional Pod Identity resources must remain disabled by default."
  }
}
