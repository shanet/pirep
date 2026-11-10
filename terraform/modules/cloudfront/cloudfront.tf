variable "acm_certificate" {}
variable "domain_assets" {}
variable "domain_origin" {}
variable "domain_tiles" {}
variable "name_prefix" {}
variable "s3_bucket_domain" {}
variable "s3_empty_map_tile_object" {}
variable "s3_root_object" {}
variable "web_domain" {}
variable "web_origin" {}

variable "web_redirect_domains" {
  type = list(string)
}

locals {
  cache_ttl        = 86400 # seconds (1 day)
  get_http_methods = ["GET", "HEAD", "OPTIONS"]
  headers          = ["Origin"]
  origin_id_s3     = "s3_assets"
  origin_id_web    = "web_server"
}

resource "aws_cloudfront_response_headers_policy" "this" {
  comment = "CORS Headers"
  name    = var.name_prefix

  cors_config {
    access_control_allow_credentials = false
    origin_override                  = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET"]
    }

    access_control_allow_origins {
      items = distinct([
        var.domain_origin,
        "www.${var.domain_origin}",
        var.web_domain,
      ])
    }
  }
}

# Allow Cloudfront to read objects in the assets bucket
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.name_prefix
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

output "cdn_assets" {
  value = aws_cloudfront_distribution.assets
}

output "cdn_tiles" {
  value = aws_cloudfront_distribution.tiles
}

output "cdn_web" {
  value = aws_cloudfront_distribution.web
}

output "origin_secret" {
  sensitive = true
  value     = random_password.origin_secret.result
}
