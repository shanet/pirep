variable "domain" {}
variable "route53_zone" {}

resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_ses_domain_mail_from" "this" {
  domain           = aws_ses_domain_identity.this.domain
  mail_from_domain = "mail.${var.domain}"
}

resource "aws_route53_record" "ses_verification" {
  name    = "_amazonses.${var.domain}"
  records = [aws_ses_domain_identity.this.verification_token]
  ttl     = 300
  type    = "TXT"
  zone_id = var.route53_zone
}

resource "aws_route53_record" "dkim_records" {
  # I guess there's always three of these? We can't use `length()` here since the length
  # isn't known until the DKIM resource is created and Terraform no-likey dynamic counts.
  count = 3

  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey"
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
  ttl     = 300
  type    = "CNAME"
  zone_id = var.route53_zone
}

resource "aws_route53_record" "spf_txt" {
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  records = ["v=spf1 include:amazonses.com -all"]
  ttl     = 300
  type    = "TXT"
  zone_id = var.route53_zone
}

resource "aws_route53_record" "spf_mx" {
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  records = ["10 feedback-smtp.us-west-2.amazonses.com"]
  ttl     = 300
  type    = "MX"
  zone_id = var.route53_zone
}
