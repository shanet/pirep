variable "asset_bucket" {}
variable "asset_host" {}
variable "backups_bucket" {}
variable "database_endpoint" {}
variable "database_password" { sensitive = true }
variable "database_username" {}
variable "name_prefix" {}
variable "smtp_password" {}
variable "smtp_username" {}
variable "tiles_host" {}

locals {
  # If adding a new environment variable here it must also be reflected in the container_definition.yml template too
  static_enviroment_variables = {
    database_endpoint    = var.database_endpoint,
    database_password    = var.database_password,
    database_username    = var.database_username,
    rails_asset_bucket   = var.asset_bucket,
    rails_asset_host     = var.asset_host,
    rails_backups_bucket = var.backups_bucket
    rails_tiles_host     = var.tiles_host,
    smtp_password        = var.smtp_password,
    smtp_username        = var.smtp_username,
  }
}

# Create a secret to be filled with values not defined in Terraform as these would otherwise be
# overwritten when the local variable above was changed if they were both in the same secret
resource "aws_secretsmanager_secret" "dynamic" {
  name = "${var.name_prefix}-dynamic"
}

resource "aws_secretsmanager_secret" "static" {
  name = "${var.name_prefix}-static"
}

resource "aws_secretsmanager_secret_version" "static" {
  secret_id     = aws_secretsmanager_secret.static.id
  secret_string = jsonencode(local.static_enviroment_variables)
}

output "secret_dynamic" {
  value = aws_secretsmanager_secret.dynamic
}

output "secret_static" {
  value = aws_secretsmanager_secret.static
}
