variable "cloudwatch_log_group" {}
variable "container_command" {}
variable "cpu" {} # vcpu units (1024 = 1 core)
variable "efs_access_point" {}
variable "efs_volume" {}
variable "enviroment_variables_secret_dynamic" {}
variable "enviroment_variables_secret_static" {}
variable "iam_role_execution" {}
variable "iam_role_task" {}
variable "image" { default = "IMAGE_PLACEHOLDER" }
variable "memory" {} # mb
variable "name_prefix" {}
variable "port" {}
variable "storage" { default = null }

resource "aws_ecs_task_definition" "this" {
  cpu                      = var.cpu
  execution_role_arn       = var.iam_role_execution
  family                   = var.name_prefix
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = var.iam_role_task

  container_definitions = jsonencode(yamldecode(templatefile("${path.module}/container_definition.yml", {
    aws_region                          = data.aws_region.current.name
    command                             = var.container_command
    enviroment_variables_secret_dynamic = var.enviroment_variables_secret_dynamic
    enviroment_variables_secret_static  = var.enviroment_variables_secret_static
    image                               = var.image
    log_group_name                      = var.cloudwatch_log_group
    name_prefix                         = var.name_prefix
    port                                = var.port
  })))

  dynamic "ephemeral_storage" {
    for_each = (var.storage != null ? [var.storage] : [])

    content {
      size_in_gib = ephemeral_storage.value
    }
  }

  volume {
    name = "efs"

    efs_volume_configuration {
      file_system_id     = var.efs_volume
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = var.efs_access_point
      }
    }
  }
}

data "aws_region" "current" {}

output "task_definition" {
  value = aws_ecs_task_definition.this
}
