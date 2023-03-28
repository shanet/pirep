variable "certificate_arn" { default = null }
variable "health_check_path_jobs" {}
variable "health_check_path_web" {}
variable "logs_bucket" {}
variable "name_prefix" {}
variable "security_group" { default = null }
variable "service_port" {}
variable "subnets" { type = list(string) }
variable "vpc_id" {}

resource "aws_lb" "load_balancer" {
  name            = var.name_prefix
  security_groups = [var.security_group]
  subnets         = var.subnets

  access_logs {
    bucket  = var.logs_bucket
    enabled = true
    prefix  = "load_balancer"
  }
}

module "service_jobs" {
  source = "./service"

  certificate_arn     = var.certificate_arn
  health_check_path   = var.health_check_path_jobs
  listener_port_http  = null
  listener_port_https = 444
  load_balancer       = aws_lb.load_balancer.arn
  name_prefix         = "${var.name_prefix}-jobs"
  service_port        = var.service_port
  vpc_id              = var.vpc_id
}

module "service_web" {
  source = "./service"

  certificate_arn   = var.certificate_arn
  health_check_path = var.health_check_path_web
  load_balancer     = aws_lb.load_balancer.arn
  name_prefix       = "${var.name_prefix}-web"
  service_port      = var.service_port
  vpc_id            = var.vpc_id
}

output "load_balancer" {
  value = aws_lb.load_balancer
}

output "target_group_jobs_blue" {
  value = module.service_jobs.target_group_blue
}

output "target_group_jobs_green" {
  value = module.service_jobs.target_group_green
}

output "target_group_web_blue" {
  value = module.service_web.target_group_blue
}

output "target_group_web_green" {
  value = module.service_web.target_group_green
}

output "listener_jobs" {
  value = module.service_jobs.listener
}

output "listener_web" {
  value = module.service_web.listener
}
