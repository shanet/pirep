# Create a task definition for running the airport imports jobs. We need a container with higher memory limits than the ones above have.
# It's not cost effective to run a container with such high CPU/memory limits for a job we only need to run once per month. Thus, this is
# a standalone task definition used to create one-off tasks with.
module "task_definition_content_packs" {
  source = "./task_definition"

  cloudwatch_log_group                = var.cloudwatch_log_groups.jobs
  container_command                   = "[bash, scripts/content_packs_creator.sh]"
  cpu                                 = 4096 # 4 vCPU
  efs_access_point                    = aws_efs_access_point.this.id
  efs_volume                          = aws_efs_file_system.this.id
  enviroment_variables_secret_dynamic = var.enviroment_variables_secret_dynamic
  enviroment_variables_secret_static  = var.enviroment_variables_secret_static
  iam_role_execution                  = var.iam_role_execution
  iam_role_task                       = var.iam_role_task
  image                               = "${var.ecr_repository_url}:latest"
  memory                              = 8192 # mb
  name_prefix                         = "${var.name_prefix}-content_packs"
  port                                = var.service_port
  storage                             = 50 # gb
}

module "task_definition_importer" {
  source = "./task_definition"

  cloudwatch_log_group                = var.cloudwatch_log_groups.jobs
  container_command                   = "[bundle, exec, rails, runner, scripts/master_data_importer.rb]"
  cpu                                 = 4096 # 4 vCPU
  efs_access_point                    = aws_efs_access_point.this.id
  efs_volume                          = aws_efs_file_system.this.id
  enviroment_variables_secret_dynamic = var.enviroment_variables_secret_dynamic
  enviroment_variables_secret_static  = var.enviroment_variables_secret_static
  iam_role_execution                  = var.iam_role_execution
  iam_role_task                       = var.iam_role_task
  image                               = "${var.ecr_repository_url}:latest"
  memory                              = 8192 # mb
  name_prefix                         = "${var.name_prefix}-importer"
  port                                = var.service_port
  storage                             = 50 # gb
}
