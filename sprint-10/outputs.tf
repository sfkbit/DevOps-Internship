output "ec2_instance_type" {
  value = var.instance_type
}

output "rds_instance_class" {
  value = var.db_instance_class
}

output "load_balancer_name" {
  value = aws_lb.app.name
}
