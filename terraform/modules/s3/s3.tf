variable "cloudfront_distributions" { type = list(string) }
variable "name_prefix" {}

resource "aws_s3_bucket" "assets" {
  bucket = "${var.name_prefix}-assets"
}

resource "aws_s3_bucket_acl" "assets" {
  acl    = "private"
  bucket = aws_s3_bucket.assets.id
}

resource "aws_s3_bucket_public_access_block" "assets" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.assets.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow Cloudfront to read objects in the assets bucket
data "aws_iam_policy_document" "assets" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]

    condition {
      test     = "StringEquals"
      values   = var.cloudfront_distributions
      variable = "AWS:SourceArn"
    }

    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets.json
}

# Delete old FAA data
resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "delete_old_faa_data"
    status = "Enabled"

    expiration {
      days = 90
    }

    filter {
      prefix = "content/"
    }
  }
}


# Default root object for the CDN so directory listings are not exposed
resource "aws_s3_object" "root_object" {
  source       = "${path.module}/index.html"
  bucket       = aws_s3_bucket.assets.bucket
  content_type = "text/html"
  key          = "index.html"
}

resource "aws_s3_object" "empty_map_tile" {
  source       = "${path.module}/empty_map_tile.webp"
  bucket       = aws_s3_bucket.assets.bucket
  content_type = "image/webp"
  key          = "empty_map_tile.webp"
}

output "assets_bucket" {
  value = aws_s3_bucket.assets
}

output "root_object_key" {
  value = aws_s3_object.root_object.key
}

output "empty_map_tile_object_key" {
  value = aws_s3_object.empty_map_tile.key
}
