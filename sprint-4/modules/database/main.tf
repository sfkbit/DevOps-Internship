resource "aws_db_subnet_group" "database" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.db_name}-subnet-group"
  }
}

resource "aws_security_group" "database" {
  name        = "${var.db_name}-security-group"
  description = "Allow PostgreSQL only from the application subnet"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from application subnet"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.app_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.db_name}-security-group"
  }
}

resource "aws_db_instance" "database" {
  identifier = var.db_name

  engine         = "postgres"
  instance_class = "db.t3.micro"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"

  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]

  backup_retention_period = var.backup_retention
  backup_window           = "02:00-03:00"
  maintenance_window      = var.maintenance_window

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = var.db_name
  }
}
