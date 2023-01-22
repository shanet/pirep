variable "certificate_arn" { default = null }
variable "health_check_path" {}
variable "name_prefix" {}
variable "publicly_accessible" { default = true }
variable "security_group" { default = null }
variable "subnets" { type = list(string) }
variable "vpc_id" {}
variable "web_port" {}

resource "aws_lb" "load_balancer" {
  name            = var.name_prefix
  security_groups = [var.security_group]
  subnets         = var.subnets
}

module "target_group_blue" {
  source = "./target_group"

  health_check_path = var.health_check_path
  name_prefix       = "${var.name_prefix}-blue"
  port              = var.web_port
  protocol          = "HTTP"
  vpc_id            = var.vpc_id
}

module "target_group_green" {
  source = "./target_group"

  health_check_path = var.health_check_path
  name_prefix       = "${var.name_prefix}-green"
  port              = var.web_port
  protocol          = "HTTP"
  vpc_id            = var.vpc_id
}

resource "aws_lb_listener" "https" {
  certificate_arn   = var.certificate_arn
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = module.target_group_green.target_group.arn
    type             = "forward"
  }

  # The blue/green deployments will swap this attribute so ignore changes on it
  lifecycle {
    ignore_changes = [default_action.0.target_group_arn]
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

output "load_balancer" {
  value = aws_lb.load_balancer
}

output "target_group_blue" {
  value = module.target_group_blue.target_group
}

output "target_group_green" {
  value = module.target_group_green.target_group
}

output "listener" {
  value = aws_lb_listener.https
}
