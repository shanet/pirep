resource "aws_s3_bucket" "backups" {
  bucket = "${var.name_prefix}-backups"
}

resource "aws_s3_bucket_public_access_block" "backups" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.backups.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Delete old backups
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "delete_old_backups"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
