variable "name_prefix" {}
variable "vpc_id" {}
variable "web_port" {}

resource "aws_security_group" "load_balancer_jobs" {
  name   = "${var.name_prefix}-load_balancer_jobs"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-load_balancer_jobs"
  }
}

resource "aws_security_group" "load_balancer_web" {
  name   = "${var.name_prefix}-load_balancer_web"
  vpc_id = var.vpc_id

  # Incoming traffic from internet
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "TCP"
    to_port     = 443
  }

  tags = {
    Name = "${var.name_prefix}-load_balancer_web"
  }
}

# Health check traffi from load balancers to ECSc
resource "aws_security_group_rule" "health_check" {
  for_each = toset([aws_security_group.load_balancer_jobs.id, aws_security_group.load_balancer_web.id])

  from_port                = var.web_port
  protocol                 = "TCP"
  security_group_id        = each.value
  source_security_group_id = aws_security_group.ecs.id
  to_port                  = var.web_port
  type                     = "egress"
}

resource "aws_security_group" "ecs" {
  name   = "${var.name_prefix}-ecs"
  vpc_id = var.vpc_id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    from_port       = var.web_port
    protocol        = "TCP"
    security_groups = [aws_security_group.load_balancer_jobs.id, aws_security_group.load_balancer_web.id]
    to_port         = var.web_port
  }

  tags = {
    Name = "${var.name_prefix}-ecs"
  }
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
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 5432
    protocol    = "TCP"
    to_port     = 5432
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

output "load_balancer_jobs" {
  value = aws_security_group.load_balancer_jobs
}

output "load_balancer_web" {
  value = aws_security_group.load_balancer_web
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
