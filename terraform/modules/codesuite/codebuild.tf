locals {
  logs_retention_period = 7 # days
}

resource "aws_codebuild_project" "image" {
  name         = "${var.name_prefix}-image"
  service_role = var.iam_role_codebuild_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    # Build on ARM so the image matches the ARM64 Fargate tasks
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux-aarch64-standard:3.0" # Amazon Linux 2023
    privileged_mode = true
    type            = "ARM_CONTAINER"

    environment_variable {
      name  = "DOCKER_HUB_USERNAME"
      value = jsondecode(data.aws_ssm_parameter.docker_hub_credentials.value)["username"]
    }

    environment_variable {
      name  = "DOCKER_HUB_PASSWORD"
      value = jsondecode(data.aws_ssm_parameter.docker_hub_credentials.value)["password"]
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = var.ecr_repository_url
    }

    # The container is named after the service
    environment_variable {
      name  = "WEB_CONTAINER_NAME"
      value = var.ecs_service_name_web
    }

    environment_variable {
      name  = "NAME_PREFIX"
      value = var.name_prefix
    }

    environment_variable {
      name  = "PORT"
      value = var.service_port
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.image.name
    }
  }

  source {
    buildspec = "buildspec_image.yml"
    type      = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "migrations" {
  name         = "${var.name_prefix}-migrations"
  service_role = var.iam_role_codebuild_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux-aarch64-standard:3.0" # Amazon Linux 2023
    type         = "ARM_CONTAINER"

    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = var.ecs_cluster_name
    }

    environment_variable {
      name  = "ECS_SERVICE_NAME"
      value = var.migrations_ecs_service
    }

    environment_variable {
      name = "MIGRATION_COMMAND"
      value = jsonencode({
        containerOverrides = [{
          command = ["bundle", "exec", "rails", "db:migrate"]
          name    = var.migrations_container_name
        }]
      })
    }

    environment_variable {
      name  = "NAME_PREFIX"
      value = var.name_prefix
    }

    environment_variable {
      name  = "TASK_DEFINITION_ARN"
      value = var.migrations_task_definition
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.migrations.name
    }
  }

  source {
    buildspec = "buildspec_migrations.yml"
    type      = "CODEPIPELINE"
  }
}

resource "aws_cloudwatch_log_group" "image" {
  name              = "/aws/codebuild/${var.name_prefix}-image"
  retention_in_days = local.logs_retention_period
}

resource "aws_cloudwatch_log_group" "migrations" {
  name              = "/aws/codebuild/${var.name_prefix}-migrations"
  retention_in_days = local.logs_retention_period
}

# This resource needs to be created manually. The expected value is of the form:
# {"username": "USERANEM", "password": "PASSWORD"}
data "aws_ssm_parameter" "docker_hub_credentials" {
  name = "DOCKER_HUB_CREDENTIALS"
}
