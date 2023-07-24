variable "assets_bucket_arn" {}
variable "backups_bucket_arn" {}
variable "cloudwatch_log_groups" { type = list(string) }
variable "deployment_bucket" {}
variable "ecr_repository" {}
variable "ecs_cluster" {}
variable "ecs_service_jobs" {}
variable "enviroment_variables_secrets" { type = list(string) }
variable "name_prefix" {}
