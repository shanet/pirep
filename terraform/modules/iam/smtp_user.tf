locals {
  name_prefix = "${var.name_prefix}-smtp"
}

resource "aws_iam_user" "smtp_user" {
  name = local.name_prefix
}

resource "aws_iam_access_key" "smtp_user" {
  user = aws_iam_user.smtp_user.name
}

data "aws_iam_policy_document" "smtp_user" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "smtp_user" {
  description = "Send emails with SES"
  name        = local.name_prefix
  policy      = data.aws_iam_policy_document.smtp_user.json
}

resource "aws_iam_user_policy_attachment" "smtp_user" {
  policy_arn = aws_iam_policy.smtp_user.arn
  user       = aws_iam_user.smtp_user.name
}

output "smtp_username" {
  value = aws_iam_access_key.smtp_user.id
}

output "smtp_password" {
  value = aws_iam_access_key.smtp_user.ses_smtp_password_v4
}
