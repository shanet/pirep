variable "cdn_assets_dns_name" {}
variable "cdn_assets_dns_zone_id" {}
variable "cdn_tiles_dns_name" {}
variable "cdn_tiles_dns_zone_id" {}
variable "domain_apex" {}
variable "domain_cdn_assets" {}
variable "domain_cdn_tiles" {}
variable "load_balancer_dns_name" {}
variable "load_balancer_dns_zone_id" {}
variable "name_prefix" {}

resource "aws_route53_zone" "this" {
  name = var.domain_apex
  tags = { Name = var.name_prefix }
}

resource "aws_route53_record" "apex" {
  name    = var.domain_apex
  type    = "A"
  zone_id = aws_route53_zone.this.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.load_balancer_dns_name
    zone_id                = var.load_balancer_dns_zone_id
  }
}

resource "aws_route53_record" "www" {
  name    = "www.${var.domain_apex}"
  type    = "A"
  zone_id = aws_route53_zone.this.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.domain_apex
    zone_id                = aws_route53_zone.this.zone_id
  }
}

resource "aws_route53_record" "cdn_assets" {
  name    = var.domain_cdn_assets
  type    = "A"
  zone_id = aws_route53_zone.this.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.cdn_assets_dns_name
    zone_id                = var.cdn_assets_dns_zone_id
  }
}

resource "aws_route53_record" "cdn_tiles" {
  name    = var.domain_cdn_tiles
  type    = "A"
  zone_id = aws_route53_zone.this.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.cdn_tiles_dns_name
    zone_id                = var.cdn_tiles_dns_zone_id
  }
}

output "cdn_assets_record" {
  value = aws_route53_record.cdn_assets
}

output "cdn_tiles_record" {
  value = aws_route53_record.cdn_tiles
}

output "zone" {
  value = aws_route53_zone.this
}
