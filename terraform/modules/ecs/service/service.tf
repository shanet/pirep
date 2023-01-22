variable "cloudwatch_log_group" {}
variable "container_command" {}
variable "container_count" {}
variable "cpu" {} # vcpu units (1024 = 1 core)
variable "ecs_cluster" {}
variable "efs_access_point" {}
variable "efs_volume" {}
variable "enviroment_variables_secret_dynamic" {}
variable "enviroment_variables_secret_static" {}
variable "iam_role_execution" {}
variable "iam_role_task" {}
variable "memory" {} # mb
variable "name_prefix" {}
variable "port" {}
variable "security_group" {}
variable "subnets" { type = list(string) }
variable "target_group_arn" {}

resource "aws_ecs_service" "service" {
  cluster                = var.ecs_cluster
  desired_count          = var.container_count
  enable_execute_command = true
  launch_type            = "FARGATE"
  name                   = var.name_prefix
  task_definition        = module.task_definition.task_definition.arn

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    container_name   = var.name_prefix
    container_port   = var.port
    target_group_arn = var.target_group_arn
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [var.security_group]
    subnets          = var.subnets
  }

  # The blue/green deployments will swap load balancer target groups and task definitions so ignore changes in them
  lifecycle {
    ignore_changes = [load_balancer, task_definition]
  }
}

module "task_definition" {
  source = "../task_definition"

  cloudwatch_log_group                = var.cloudwatch_log_group
  container_command                   = var.container_command
  cpu                                 = var.cpu
  efs_access_point                    = var.efs_access_point
  efs_volume                          = var.efs_volume
  enviroment_variables_secret_dynamic = var.enviroment_variables_secret_dynamic
  enviroment_variables_secret_static  = var.enviroment_variables_secret_static
  iam_role_execution                  = var.iam_role_execution
  iam_role_task                       = var.iam_role_task
  memory                              = var.memory
  name_prefix                         = var.name_prefix
  port                                = var.port
}

output "task_definition" {
  value = module.task_definition.task_definition
}

output "service" {
  value = aws_ecs_service.service
}
