variable "health_check_path" {}
variable "name_prefix" {}
variable "port" {}
variable "protocol" {}
variable "vpc_id" {}

resource "aws_lb_target_group" "target_group" {
  name              = var.name_prefix
  port              = var.port
  protocol          = var.protocol
  proxy_protocol_v2 = false
  target_type       = "ip"
  vpc_id            = var.vpc_id

  health_check {
    path = var.health_check_path
  }
}

output "target_group" {
  value = aws_lb_target_group.target_group
}
