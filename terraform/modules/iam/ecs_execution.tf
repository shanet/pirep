data "aws_iam_policy_document" "ecs_execution_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "ecs_execution_role_policy" {
  statement {
    resources = [for log_group in var.cloudwatch_log_groups : "${log_group}:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    resources = [var.ecr_repository]

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
  }

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.enviroment_variables_secrets
  }
}

resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  policy = data.aws_iam_policy_document.ecs_execution_role_policy.json
  role   = aws_iam_role.ecs_execution_role.id
}

resource "aws_iam_role" "ecs_execution_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role_policy.json
  name               = "${var.name_prefix}-ecs_execution"
}

output "ecs_execution_role" {
  value = aws_iam_role.ecs_execution_role
}
