output "database_endpoint" {
  value = aws_db_instance.database.endpoint
}

output "database_port" {
  value = aws_db_instance.database.port
}

output "security_group_id" {
  value = aws_security_group.database.id
}

output "subnet_group_name" {
  value = aws_db_subnet_group.database.name
}
