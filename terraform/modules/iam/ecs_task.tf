data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "ecs_task_role_policy" {
  # Used for ECS Exec access to containers
  statement {
    resources = ["*"]

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
  }

  statement {
    actions = ["s3:*"]

    resources = [
      var.assets_bucket_arn,
      "${var.assets_bucket_arn}/*",
    ]
  }

  # Allow the ECS service to start the importer task
  statement {
    actions   = ["ecs:DescribeServices"]
    resources = [var.ecs_service_jobs]
  }

  statement {
    actions   = ["ecs:ListTaskDefinitions", "ecs:RunTask"]
    resources = ["*"]
  }

  statement {
    actions = ["iam:PassRole"]

    resources = [
      aws_iam_role.ecs_execution_role.arn,
      aws_iam_role.ecs_task_role.arn,
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  policy = data.aws_iam_policy_document.ecs_task_role_policy.json
  role   = aws_iam_role.ecs_task_role.id
}

resource "aws_iam_role" "ecs_task_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
  name               = "${var.name_prefix}-ecs_task"
}

output "ecs_task_role" {
  value = aws_iam_role.ecs_task_role
}
