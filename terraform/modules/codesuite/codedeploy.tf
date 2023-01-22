resource "aws_codedeploy_app" "this" {
  compute_platform = "ECS"
  name             = var.name_prefix
}

module "deployment_group_jobs" {
  source = "./deployment_group"

  codedeploy_application     = aws_codedeploy_app.this.name
  ecs_cluster_name           = var.ecs_cluster_name
  ecs_service_name           = var.services.jobs.ecs_service_name
  iam_role_codedeploy_arn    = var.iam_role_codedeploy_arn
  load_balancer_listener_arn = var.services.jobs.load_balancer_listener_arn
  name_prefix                = var.services.jobs.name_prefix
  target_group_blue_name     = var.services.jobs.target_group_blue_name
  target_group_green_name    = var.services.jobs.target_group_green_name
}

module "deployment_group_web" {
  source = "./deployment_group"

  codedeploy_application     = aws_codedeploy_app.this.name
  ecs_cluster_name           = var.ecs_cluster_name
  ecs_service_name           = var.services.web.ecs_service_name
  iam_role_codedeploy_arn    = var.iam_role_codedeploy_arn
  load_balancer_listener_arn = var.services.web.load_balancer_listener_arn
  name_prefix                = var.services.web.name_prefix
  target_group_blue_name     = var.services.web.target_group_blue_name
  target_group_green_name    = var.services.web.target_group_green_name
}
