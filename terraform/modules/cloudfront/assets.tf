locals {
  s3_path_pattern_content = "/content/*"
  s3_path_pattern_uploads = "/uploads/*"
}

resource "aws_cloudfront_distribution" "assets" {
  aliases             = [var.domain_assets]
  comment             = "${var.name_prefix}-assets"
  default_root_object = var.s3_root_object
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods            = local.get_http_methods
    cached_methods             = local.get_http_methods
    compress                   = true
    default_ttl                = local.cache_ttl
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
      allowed_methods            = local.get_http_methods
      cached_methods             = local.get_http_methods
      compress                   = true
      default_ttl                = local.cache_ttl
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
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}
