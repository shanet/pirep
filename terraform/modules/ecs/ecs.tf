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
variable "subnets" { type = list(string) }
variable "target_group_arn_jobs" {}
variable "target_group_arn_web" {}

resource "aws_ecs_cluster" "this" {
  name = var.name_prefix
}

module "service_jobs" {
  source = "./service"

  cloudwatch_log_group = var.cloudwatch_log_groups.jobs
  container_command    = "[bundle, exec, good_job, start]"
  container_count      = 0
  # container_count                     = 1
  cpu                                 = 512 # 0.5 vCPU
  ecs_cluster                         = aws_ecs_cluster.this.id
  efs_access_point                    = aws_efs_access_point.this.id
  efs_volume                          = aws_efs_file_system.this.id
  enviroment_variables_secret_dynamic = var.enviroment_variables_secret_dynamic
  enviroment_variables_secret_static  = var.enviroment_variables_secret_static
  iam_role_execution                  = var.iam_role_execution
  iam_role_task                       = var.iam_role_task
  memory                              = 1024 # mb
  name_prefix                         = "${var.name_prefix}-jobs"
  port                                = var.service_port
  security_group                      = var.security_group_ecs
  subnets                             = var.subnets
  target_group_arn                    = var.target_group_arn_jobs
}

module "service_web" {
  source = "./service"

  cloudwatch_log_group = var.cloudwatch_log_groups.web
  # container_command                   = "[puma, --config, config/puma.rb]"
  container_command                   = "[bash, scripts/ecs_main.sh]"
  container_count                     = 1
  cpu                                 = 512 # 0.5 vCPU
  ecs_cluster                         = aws_ecs_cluster.this.id
  efs_access_point                    = aws_efs_access_point.this.id
  efs_volume                          = aws_efs_file_system.this.id
  enviroment_variables_secret_dynamic = var.enviroment_variables_secret_dynamic
  enviroment_variables_secret_static  = var.enviroment_variables_secret_static
  iam_role_execution                  = var.iam_role_execution
  iam_role_task                       = var.iam_role_task
  memory                              = 2048 # mb
  name_prefix                         = "${var.name_prefix}-web"
  port                                = var.service_port
  security_group                      = var.security_group_ecs
  subnets                             = var.subnets
  target_group_arn                    = var.target_group_arn_web
}

output "cluster" {
  value = aws_ecs_cluster.this
}

output "task_definition_jobs" {
  value = module.service_jobs.task_definition
}

output "task_definition_web" {
  value = module.service_web.task_definition
}

output "service_jobs" {
  value = module.service_jobs.service
}

output "service_web" {
  value = module.service_web.service
}
