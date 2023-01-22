data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["codebuild.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "codebuild_role_policy" {
  statement {
    resources = ["*"]

    actions = [
      "codestar-connections:UseConnection",
      "ecr:GetAuthorizationToken",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:RunTask",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    resources = ["${var.deployment_bucket}/*"]

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
  }

  statement {
    resources = [var.ecr_repository]

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:TagResource",
      "ecr:UploadLayerPart",
    ]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["ecs-tasks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  policy = data.aws_iam_policy_document.codebuild_role_policy.json
  role   = aws_iam_role.codebuild_role.id
}

resource "aws_iam_role" "codebuild_role" {
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
  name               = "${var.name_prefix}-codebuild"
}

output "codebuild_role" {
  value = aws_iam_role.codebuild_role
}
