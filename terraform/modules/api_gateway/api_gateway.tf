variable "certificate_arn" {}
variable "domain" {}
variable "name_prefix" {}
variable "security_group" {}
variable "service_discovery_service_arn" {}

variable "subnets" {
  type = list(string)
}

resource "aws_apigatewayv2_api" "this" {
  # Only allow access through the custom domain
  disable_execute_api_endpoint = true
  name                         = var.name_prefix
  protocol_type                = "HTTP"
}

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = var.name_prefix
  security_group_ids = [var.security_group]
  subnet_ids         = var.subnets
}

resource "aws_apigatewayv2_integration" "web" {
  api_id                 = aws_apigatewayv2_api.this.id
  connection_id          = aws_apigatewayv2_vpc_link.this.id
  connection_type        = "VPC_LINK"
  integration_method     = "ANY"
  integration_type       = "HTTP_PROXY"
  integration_uri        = var.service_discovery_service_arn
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.web.id}"
}

# Using the default stage avoids having the stage name prepended to request paths
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  auto_deploy = true
  name        = "$default"
}

# Cloudfront forwards the viewer's Host header so requests are routed to this custom domain and the app sees the real host
resource "aws_apigatewayv2_domain_name" "this" {
  domain_name = var.domain

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this.id
  stage       = aws_apigatewayv2_stage.default.id
}

output "api" {
  value = aws_apigatewayv2_api.this
}

output "origin_domain" {
  value = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].target_domain_name
}
