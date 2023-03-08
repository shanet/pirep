variable "acm_certificate" {}
variable "domain_assets" {}
variable "domain_origin" {}
variable "domain_tiles" {}
variable "name_prefix" {}
variable "s3_bucket_domain" {}
variable "s3_empty_map_tile_object" {}
variable "s3_root_object" {}

locals {
  headers                 = ["Origin"]
  http_methods            = ["GET", "HEAD", "OPTIONS"]
  origin_id_s3            = "s3_assets"
  origin_id_web           = "web_server"
  s3_path_pattern_content = "/content/*"
  s3_path_pattern_uploads = "/uploads/*"
}

resource "aws_cloudfront_distribution" "assets" {
  aliases             = [var.domain_assets]
  comment             = "${var.name_prefix}-assets"
  default_root_object = var.s3_root_object
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods            = local.http_methods
    cached_methods             = local.http_methods
    compress                   = true
    default_ttl                = 86400 # seconds (1 day)
    min_ttl                    = 86400 # seconds (1 day)
    response_headers_policy_id = aws_cloudfront_response_headers_policy.this.id
    target_origin_id           = local.origin_id_web
    viewer_protocol_policy     = "redirect-to-https"

    forwarded_values {
      headers      = local.headers
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = toset([local.s3_path_pattern_content, local.s3_path_pattern_uploads])

    content {
      allowed_methods            = local.http_methods
      cached_methods             = local.http_methods
      compress                   = true
      default_ttl                = 86400 # seconds (1 day)
      path_pattern               = ordered_cache_behavior.value
      response_headers_policy_id = aws_cloudfront_response_headers_policy.this.id
      target_origin_id           = local.origin_id_s3
      viewer_protocol_policy     = "redirect-to-https"

      forwarded_values {
        headers      = local.headers
        query_string = false

        cookies {
          forward = "none"
        }
      }
    }
  }

  # Web server
  origin {
    domain_name = var.domain_origin
    origin_id   = local.origin_id_web

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # S3 assets bucket
  origin {
    domain_name              = var.s3_bucket_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    origin_id                = local.origin_id_s3
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "tiles" {
  aliases             = [var.domain_tiles]
  comment             = "${var.name_prefix}-tiles"
  default_root_object = var.s3_root_object
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"

  custom_error_response {
    error_caching_min_ttl = 600 # 10 minutes
    error_code            = 403
    response_code         = 200
    response_page_path    = "/${var.s3_empty_map_tile_object}"
  }

  custom_error_response {
    error_caching_min_ttl = 600 # 10 minutes
    error_code            = 404
    response_code         = 200
    response_page_path    = "/${var.s3_empty_map_tile_object}"
  }

  default_cache_behavior {
    allowed_methods            = local.http_methods
    cached_methods             = local.http_methods
    compress                   = true
    default_ttl                = 86400 # seconds (1 day)
    response_headers_policy_id = aws_cloudfront_response_headers_policy.this.id
    target_origin_id           = local.origin_id_s3
    viewer_protocol_policy     = "redirect-to-https"

    forwarded_values {
      headers      = local.headers
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name              = var.s3_bucket_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    origin_id                = local.origin_id_s3
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }
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
      items = [
        var.domain_origin,
        "www.${var.domain_origin}",
      ]
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
