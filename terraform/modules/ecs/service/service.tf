variable "cloudwatch_log_group" {}
variable "container_command" {}
variable "container_count" {}
variable "cpu" {} # vcpu units (1024 = 1 core)
variable "deployment_controller" { default = "CODE_DEPLOY" }
variable "ecs_cluster" {}
variable "efs_access_point" {}
variable "efs_volume" {}
variable "enviroment_variables_secret_dynamic" {}
variable "enviroment_variables_secret_static" {}
variable "health_check_path" { default = null }
variable "iam_role_execution" {}
variable "iam_role_task" {}
variable "image" { default = "IMAGE_PLACEHOLDER" }
variable "memory" {} # mb
variable "name_prefix" {}
variable "port" {}
variable "security_group" {}
variable "service_registry_arn" { default = null }
variable "subnets" { type = list(string) }
variable "target_group_arn" { default = null }

resource "aws_ecs_service" "service" {
  cluster                = var.ecs_cluster
  desired_count          = var.container_count
  enable_execute_command = true
  launch_type            = "FARGATE"
  name                   = var.name_prefix
  task_definition        = module.task_definition.task_definition.arn

  deployment_controller {
    type = var.deployment_controller
  }

  # Roll back automatically if new tasks fail to become healthy
  dynamic "deployment_circuit_breaker" {
    for_each = (var.deployment_controller == "ECS" ? [1] : [])

    content {
      enable   = true
      rollback = true
    }
  }

  dynamic "load_balancer" {
    for_each = (var.target_group_arn != null ? [var.target_group_arn] : [])

    content {
      container_name   = var.name_prefix
      container_port   = var.port
      target_group_arn = load_balancer.value
    }
  }

  dynamic "service_registries" {
    for_each = (var.service_registry_arn != null ? [var.service_registry_arn] : [])

    content {
      container_name = var.name_prefix
      container_port = var.port
      registry_arn   = service_registries.value
    }
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
  health_check_path                   = var.health_check_path
  iam_role_execution                  = var.iam_role_execution
  iam_role_task                       = var.iam_role_task
  image                               = var.image
  memory                              = var.memory
  name_prefix                         = var.name_prefix
  port                                = var.port
}

output "service" {
  value = aws_ecs_service.service
}

output "task_definition" {
  value = module.task_definition.task_definition
}
