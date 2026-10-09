terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

module "database" {
  source = "./modules/database"

  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  vpc_id                 = var.vpc_id
  db_subnet_ids          = var.db_subnet_ids
  app_subnet_cidr        = var.app_subnet_cidr
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  backup_retention       = var.backup_retention
  maintenance_window     = var.maintenance_window
}
