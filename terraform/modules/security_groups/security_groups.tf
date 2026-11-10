variable "name_prefix" {}
variable "service_port" {}
variable "vpc_id" {}

resource "aws_security_group" "ecs" {
  name   = "${var.name_prefix}-ecs"
  vpc_id = var.vpc_id

  egress {
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 0
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "-1"
    to_port          = 0
  }

  ingress {
    from_port       = var.service_port
    protocol        = "TCP"
    security_groups = [aws_security_group.vpc_link.id]
    to_port         = var.service_port
  }

  tags = {
    Name = "${var.name_prefix}-ecs"
  }
}

resource "aws_security_group" "vpc_link" {
  name   = "${var.name_prefix}-vpc_link"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-vpc_link"
  }
}

# Traffic from the API Gateway VPC link to ECS
resource "aws_security_group_rule" "vpc_link" {
  from_port                = var.service_port
  protocol                 = "TCP"
  security_group_id        = aws_security_group.vpc_link.id
  source_security_group_id = aws_security_group.ecs.id
  to_port                  = var.service_port
  type                     = "egress"
}

# NFS traffic from ECS to EFS
resource "aws_security_group" "efs" {
  name   = "${var.name_prefix}-efs"
  vpc_id = var.vpc_id

  egress {
    from_port       = 2049
    protocol        = "TCP"
    security_groups = [aws_security_group.ecs.id]
    to_port         = 2049
  }

  ingress {
    from_port       = 2049
    protocol        = "TCP"
    security_groups = [aws_security_group.ecs.id]
    to_port         = 2049
  }

  tags = {
    Name = "${var.name_prefix}-efs"
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.name_prefix}-rds"
  vpc_id = var.vpc_id

  egress {
    from_port       = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.ecs.id]
    to_port         = 5432
  }

  ingress {
    from_port       = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.ecs.id]
    to_port         = 5432
  }

  tags = {
    Name = "${var.name_prefix}-rds"
  }
}

output "ecs" {
  value = aws_security_group.ecs
}

output "efs" {
  value = aws_security_group.efs
}

output "rds" {
  value = aws_security_group.rds
}

output "vpc_link" {
  value = aws_security_group.vpc_link
}
