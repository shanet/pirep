variable "certificate_arn" {}
variable "health_check_path" {}
variable "listener_port_http" { default = 80 }
variable "listener_port_https" { default = 443 }
variable "load_balancer" {}
variable "name_prefix" {}
variable "service_port" {}
variable "vpc_id" {}

module "target_group_blue" {
  source = "../target_group"

  health_check_path = var.health_check_path
  name_prefix       = "${var.name_prefix}-blue"
  port              = var.service_port
  protocol          = "HTTP"
  vpc_id            = var.vpc_id
}

module "target_group_green" {
  source = "../target_group"

  health_check_path = var.health_check_path
  name_prefix       = "${var.name_prefix}-green"
  port              = var.service_port
  protocol          = "HTTP"
  vpc_id            = var.vpc_id
}

resource "aws_lb_listener" "https" {
  count = (var.listener_port_https != null ? 1 : 0)

  certificate_arn   = var.certificate_arn
  load_balancer_arn = var.load_balancer
  port              = var.listener_port_https
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

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
  count = (var.listener_port_http != null ? 1 : 0)

  load_balancer_arn = var.load_balancer
  port              = var.listener_port_http
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = var.listener_port_https
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
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
