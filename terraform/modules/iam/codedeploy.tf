data "aws_iam_policy_document" "codedeploy_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["codedeploy.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "codedeploy_role_policy" {
  statement {
    resources = ["*"]

    actions = [
      "ecs:*",
      "elasticloadbalancing:*",
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

resource "aws_iam_role_policy" "codedeploy_role_policy" {
  policy = data.aws_iam_policy_document.codedeploy_role_policy.json
  role   = aws_iam_role.codedeploy_role.id
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_role.id
}

resource "aws_iam_role" "codedeploy_role" {
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role_policy.json
  name               = "${var.name_prefix}-codedeploy"
}

output "codedeploy_role" {
  value = aws_iam_role.codedeploy_role
}
