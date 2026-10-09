variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "db_name" {
  type    = string
  default = "sprint4db"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "app_subnet_cidr" {
  type = string
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "backup_retention" {
  type    = number
  default = 7
}

variable "maintenance_window" {
  type    = string
  default = "sun:03:00-sun:04:00"
}
