# This distribution redirects HTTP -> HTTPS traffic since the API Gateway only listens on HTTPS
resource "aws_cloudfront_distribution" "web" {
  aliases         = concat([var.web_domain], var.web_redirect_domains)
  comment         = "${var.name_prefix}-web"
  enabled         = true
  http_version    = "http2and3"
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.none.id
    cached_methods           = ["GET", "HEAD"]
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    target_origin_id         = local.origin_id_web
    viewer_protocol_policy   = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.web_redirect.arn
    }
  }

  origin {
    domain_name = var.web_origin
    origin_id   = local.origin_id_web

    # Let the app know a request came through Cloudfront so it can trust the CloudFront-Viewer-Address header for the client IP
    custom_header {
      name  = "X-Origin-Secret"
      value = random_password.origin_secret.result
    }

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_read_timeout    = 30 # seconds (API Gateway's maximum integration timeout)
      origin_ssl_protocols   = ["TLSv1.2"]
    }
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

resource "random_password" "origin_secret" {
  length  = 50
  special = false
}

# The origin can only serve a single domain so redirect any other domains (such as `www`) to it
resource "aws_cloudfront_function" "web_redirect" {
  comment = "Redirect alternate domains to ${var.web_domain}"
  name    = "${var.name_prefix}-https_redirect"
  publish = true
  runtime = "cloudfront-js-2.0"

  code = <<-EOF
    function handler(event) {
      var request = event.request;

      if (request.headers.host.value === '${var.web_domain}') {
        return request;
      }

      return {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {location: {value: 'https://${var.web_domain}' + request.uri}},
      };
    }
  EOF
}

data "aws_cloudfront_cache_policy" "none" {
  name = "Managed-CachingDisabled"
}

# Include the Host header and Cloudfront headers such as CloudFront-Viewer-Address (the client IP)
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewerAndCloudFrontHeaders-2022-06"
}
