output "database_endpoint" {
  value = module.database.database_endpoint
}

output "database_port" {
  value = module.database.database_port
}

output "database_security_group" {
  value = module.database.security_group_id
}

output "database_subnet_group" {
  value = module.database.subnet_group_name
}
