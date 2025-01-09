variable "name_prefix" {}
variable "security_group" {}
variable "subnet_group" {}

locals {
  instance_class = "db.t4g.micro"
}

resource "random_string" "password" {
  # Postgres has issues with some special characters in the passwords so avoid them entirely
  length  = 50
  special = false
}

resource "aws_db_parameter_group" "db_parameters" {
  family = "postgres14"
  name   = var.name_prefix

  parameter {
    name  = "rds.force_ssl"
    value = 1
  }
}

resource "aws_db_instance" "database" {
  allocated_storage         = 100           # gb
  backup_retention_period   = 30            # days
  backup_window             = "10:00-10:30" # UTC
  ca_cert_identifier        = "rds-ca-rsa2048-g1"
  db_subnet_group_name      = var.subnet_group
  deletion_protection       = true
  engine                    = "postgres"
  engine_version            = "14.12"
  final_snapshot_identifier = "${var.name_prefix}-final"
  identifier                = var.name_prefix
  instance_class            = local.instance_class
  maintenance_window        = "mon:10:30-mon:11:00"
  multi_az                  = false
  parameter_group_name      = aws_db_parameter_group.db_parameters.name
  password                  = random_string.password.result
  publicly_accessible       = false
  storage_type              = "gp2"
  username                  = "root"
  vpc_security_group_ids    = [var.security_group]
}

output "database_endpoint" {
  value = split(":", aws_db_instance.database.endpoint)[0]
}

output "database_password" {
  sensitive = true
  value     = random_string.password.result
}

output "database_username" {
  value = aws_db_instance.database.username
}
