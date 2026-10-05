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
  description = "Names of the public networks."
  value = [
    docker_network.public_1.name,
    docker_network.public_2.name
  ]
}

output "private_networks" {
  description = "Names of the private networks."
  value = [
    docker_network.private_1.name,
    docker_network.private_2.name
  ]
}
output "resource_size" {
  description = "Configured resource size profile for the environment."
  value       = var.resource_size
}
