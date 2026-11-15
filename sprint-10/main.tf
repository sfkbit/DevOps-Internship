terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "sprint10-web-server"
  }
}

resource "aws_db_instance" "app" {
  identifier                  = "sprint10-app-db"
  allocated_storage           = var.db_allocated_storage
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = var.db_instance_class
  username                    = "cost_estimation"
  manage_master_user_password = true
  storage_type                = "gp3"
  publicly_accessible         = false
  skip_final_snapshot         = true

  tags = {
    Name = "sprint10-database"
  }
}

resource "aws_lb" "app" {
  name               = "sprint10-app-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "sprint10-load-balancer"
  }
}
