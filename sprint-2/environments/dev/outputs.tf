output "public_networks" {
  description = "Names of the public networks."
  value       = module.network.public_networks
}

output "private_networks" {
  description = "Names of the private networks."
  value       = module.network.private_networks
}

output "public_network_ids" {
  description = "IDs of the public networks."
  value       = module.network.public_network_ids
}

output "private_network_ids" {
  description = "IDs of the private networks."
  value       = module.network.private_network_ids
}
output "resource_size" {
  description = "Configured resource size profile."
  value       = module.network.resource_size
}
