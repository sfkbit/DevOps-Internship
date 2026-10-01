output "vpc_cidr" {
  description = "CIDR block representing the local VPC."
  value       = var.vpc_cidr
}

output "public_network_ids" {
  description = "IDs of the public networks."
  value = [
    docker_network.public_1.id,
    docker_network.public_2.id
  ]
}

output "private_network_ids" {
  description = "IDs of the private networks."
  value = [
    docker_network.private_1.id,
    docker_network.private_2.id
  ]
}

output "public_networks" {
  description = "Public network names."
  value = [
    docker_network.public_1.name,
    docker_network.public_2.name
  ]
}

output "private_networks" {
  description = "Private network names."
  value = [
    docker_network.private_1.name,
    docker_network.private_2.name
  ]
}
