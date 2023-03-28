resource "aws_s3_bucket" "logs" {
  bucket = "${var.name_prefix}-logs"
}

resource "aws_s3_bucket_acl" "logs" {
  acl    = "private"
  bucket = aws_s3_bucket.logs.id
}

resource "aws_s3_bucket_public_access_block" "logs" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.logs.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow ELB to place logs into the log bucket
data "aws_iam_policy_document" "logs" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/load_balancer/*"]

    principals {
      # This ARN is managed by AWS. See the list here: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
      identifiers = ["arn:aws:iam::797873946194:root"]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json
}

# Delete old logs
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
