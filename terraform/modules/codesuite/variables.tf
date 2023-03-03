variable "ecr_repository_url" {}
variable "ecs_cluster_name" {}
variable "github_repository" {}
variable "iam_role_codebuild_arn" {}
variable "iam_role_codedeploy_arn" {}
variable "iam_role_codepipeline_arn" {}
variable "name_prefix" {}
variable "service_port" {}

variable "services" { type = map(
  object({
    ecs_service_name           = string
    load_balancer_listener_arn = string
    name_prefix                = string
    target_group_blue_name     = string
    target_group_green_name    = string
    task_definition_arn        = string
  })
) }
