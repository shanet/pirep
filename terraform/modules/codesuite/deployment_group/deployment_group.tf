variable "codedeploy_application" {}
variable "ecs_cluster_name" {}
variable "ecs_service_name" {}
variable "iam_role_codedeploy_arn" {}
variable "load_balancer_listener_arn" {}
variable "name_prefix" {}
variable "target_group_blue_name" {}
variable "target_group_green_name" {}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = var.codedeploy_application
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = var.name_prefix
  service_role_arn       = var.iam_role_codedeploy_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.load_balancer_listener_arn]
      }

      target_group {
        name = var.target_group_blue_name
      }

      target_group {
        name = var.target_group_green_name
      }
    }
  }
}

output "group" {
  value = aws_codedeploy_deployment_group.this
}
