resource "aws_cloudfront_distribution" "tiles" {
  aliases             = [var.domain_tiles]
  comment             = "${var.name_prefix}-tiles"
  default_root_object = var.s3_root_object
  enabled             = true
  http_version        = "http2and3"
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
    allowed_methods            = local.get_http_methods
    cached_methods             = local.get_http_methods
    compress                   = true
    default_ttl                = local.cache_ttl
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
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}
