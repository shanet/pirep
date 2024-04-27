resource "aws_codebuild_project" "image" {
  name         = "${var.name_prefix}-image"
  service_role = var.iam_role_codebuild_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:6.0" # Ubuntu 22.04
    privileged_mode = true
    type            = "LINUX_CONTAINER"

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

    dynamic "environment_variable" {
      for_each = (contains(keys(var.services), "jobs") ? [1] : [])
      content {
        name  = "ECS_SERVICE_NAME_JOBS"
        value = var.services.jobs.ecs_service_name
      }
    }

    dynamic "environment_variable" {
      for_each = (contains(keys(var.services), "web") ? [1] : [])
      content {
        name  = "ECS_SERVICE_NAME_WEB"
        value = var.services.web.ecs_service_name
      }
    }

    environment_variable {
      name  = "NAME_PREFIX"
      value = var.name_prefix
    }

    environment_variable {
      name  = "PORT"
      value = var.service_port
    }

    dynamic "environment_variable" {
      for_each = (contains(keys(var.services), "jobs") ? [1] : [])
      content {
        name  = "TASK_DEFINITION_JOBS_ARN"
        value = var.services.jobs.task_definition_arn
      }
    }

    dynamic "environment_variable" {
      for_each = (contains(keys(var.services), "web") ? [1] : [])
      content {
        name  = "TASK_DEFINITION_WEB_ARN"
        value = var.services.web.task_definition_arn
      }
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
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:6.0" # Ubuntu 22.04
    privileged_mode = true
    type            = "LINUX_CONTAINER"

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

  source {
    buildspec = "buildspec_migrations.yml"
    type      = "CODEPIPELINE"
  }
}

# This resource needs to be created manually. The expected value is of the form:
# {"username": "USERANEM", "password": "PASSWORD"}
data "aws_ssm_parameter" "docker_hub_credentials" {
  name = "DOCKER_HUB_CREDENTIALS"
}
