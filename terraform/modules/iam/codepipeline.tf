data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["codepipeline.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "codepipeline_role_policy" {
  statement {
    resources = ["*"]

    actions = [
      "codebuild:*",
      "codecommit:*",
      "codedeploy:*",
      "codestar-connections:UseConnection",
      "ecs:RegisterTaskDefinition",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListObjects",
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

resource "aws_iam_role_policy" "codepipeline_role_policy" {
  policy = data.aws_iam_policy_document.codepipeline_role_policy.json
  role   = aws_iam_role.codepipeline_role.id
}

resource "aws_iam_role" "codepipeline_role" {
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
  name               = "${var.name_prefix}-codepipeline"
}

output "codepipeline_role" {
  value = aws_iam_role.codepipeline_role
}
