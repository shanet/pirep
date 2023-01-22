variable "name_prefix" {}

locals {
  log_retention_period = 60 # days
}

resource "aws_cloudwatch_log_group" "jobs" {
  name              = "${var.name_prefix}-jobs"
  retention_in_days = local.log_retention_period
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "${var.name_prefix}-web"
  retention_in_days = local.log_retention_period
}

output "log_group_jobs" {
  value = aws_cloudwatch_log_group.jobs
}

output "log_group_web" {
  value = aws_cloudwatch_log_group.web
}
