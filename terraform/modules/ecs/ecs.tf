variable "cloudwatch_log_groups" {
  type = object({
    jobs = string,
    web  = string,
  })
}

variable "ecr_repository_url" {}
variable "enviroment_variables_secret_dynamic" {}
variable "enviroment_variables_secret_static" {}
variable "iam_role_execution" {}
variable "iam_role_task" {}
variable "name_prefix" {}
variable "security_group_ecs" {}
variable "security_group_efs" {}
variable "service_port" {}
variable "service_registry_arn_web" {}
variable "subnets" { type = list(string) }

resource "aws_ecs_cluster" "this" {
  name = var.name_prefix
}

# Web service fronted by Cloudfront and API Gateway (via Cloud Map) using ECS rolling deployments
module "service_web" {
  source = "./service"

  cloudwatch_log_group                = var.cloudwatch_log_groups.web
  container_command                   = "[bash, scripts/ecs_main.sh]"
  container_count                     = 1
  cpu                                 = 512 # 0.5 vCPU
  ecs_cluster                         = aws_ecs_cluster.this.id
  efs_access_point                    = aws_efs_access_point.this.id
  efs_volume                          = aws_efs_file_system.this.id
  enviroment_variables_secret_dynamic = var.enviroment_variables_secret_dynamic
  enviroment_variables_secret_static  = var.enviroment_variables_secret_static
  health_check_path                   = "/health"
  iam_role_execution                  = var.iam_role_execution
  iam_role_task                       = var.iam_role_task
  image                               = "${var.ecr_repository_url}:latest"
  memory                              = 2048 # mb
  name_prefix                         = "${var.name_prefix}-web"
  port                                = var.service_port
  security_group                      = var.security_group_ecs
  service_registry_arn                = var.service_registry_arn_web
  subnets                             = var.subnets
}

output "cluster" {
  value = aws_ecs_cluster.this
}

output "task_definition_migrations" {
  value = module.task_definition_migrations.task_definition
}

output "service_web" {
  value = module.service_web.service
}
