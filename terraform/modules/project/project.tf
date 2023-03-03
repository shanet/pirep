terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.us_east_1]
    }
  }
}

variable "domain" {}
variable "enviroment" {}

locals {
  domain_assets_cdn = "cdn.${var.domain}"
  domain_tiles_cdn  = "tiles.${var.domain}"
  github_repository = "shanet/pirep"
  name_prefix       = "pirep-${var.enviroment}"
  service_port      = 8080
}

# Cloudfront requires that certificates used with it be located in us-east-1
module "acm_us_east_1" {
  source = "../acm"

  domain       = var.domain
  name_prefix  = local.name_prefix
  route53_zone = module.route53.zone

  providers = {
    aws = aws.us_east_1
  }
}

module "acm_us_west_2" {
  source = "../acm"

  domain       = var.domain
  name_prefix  = local.name_prefix
  route53_zone = module.route53.zone
}

module "cloudfront" {
  source = "../cloudfront"

  acm_certificate          = module.acm_us_east_1.certificate_arn
  domain_assets            = local.domain_assets_cdn
  domain_origin            = var.domain
  domain_tiles             = local.domain_tiles_cdn
  name_prefix              = local.name_prefix
  s3_bucket_domain         = module.s3.assets_bucket.bucket_regional_domain_name
  s3_empty_map_tile_object = module.s3.empty_map_tile_object_key
  s3_root_object           = module.s3.root_object_key
}

module "cloudwatch" {
  source = "../cloudwatch"

  name_prefix = local.name_prefix
}

module "codesuite" {
  source = "../codesuite"

  ecr_repository_url        = module.ecr.repository.repository_url
  ecs_cluster_name          = module.ecs.cluster.name
  github_repository         = local.github_repository
  iam_role_codebuild_arn    = module.iam.codebuild_role.arn
  iam_role_codedeploy_arn   = module.iam.codedeploy_role.arn
  iam_role_codepipeline_arn = module.iam.codepipeline_role.arn
  name_prefix               = local.name_prefix
  service_port              = local.service_port

  services = {
    jobs = {
      ecs_service_name           = module.ecs.service_jobs.name
      load_balancer_listener_arn = module.load_balancer.listener_jobs.arn
      name_prefix                = "${local.name_prefix}-jobs"
      target_group_blue_name     = module.load_balancer.target_group_jobs_blue.name
      target_group_green_name    = module.load_balancer.target_group_jobs_green.name
      task_definition_arn        = module.ecs.task_definition_jobs.arn
    },
    web = {
      ecs_service_name           = module.ecs.service_web.name
      load_balancer_listener_arn = module.load_balancer.listener_web.arn
      name_prefix                = "${local.name_prefix}-web"
      target_group_blue_name     = module.load_balancer.target_group_web_blue.name
      target_group_green_name    = module.load_balancer.target_group_web_green.name
      task_definition_arn        = module.ecs.task_definition_web.arn
    }
  }
}

module "ecr" {
  source = "../ecr"

  name_prefix = local.name_prefix
}

module "ecs" {
  source = "../ecs"

  ecr_repository_url                  = module.ecr.repository.repository_url
  enviroment_variables_secret_dynamic = module.secretsmanager.secret_dynamic.arn
  enviroment_variables_secret_static  = module.secretsmanager.secret_static.arn
  iam_role_execution                  = module.iam.ecs_execution_role.arn
  iam_role_task                       = module.iam.ecs_task_role.arn
  name_prefix                         = local.name_prefix
  security_group_ecs                  = module.security_groups.ecs.id
  security_group_efs                  = module.security_groups.efs.id
  service_port                        = local.service_port
  subnets                             = [for subnet in module.vpc.public_subnets : subnet.id]
  target_group_arn_jobs               = module.load_balancer.target_group_jobs_green.arn
  target_group_arn_web                = module.load_balancer.target_group_web_green.arn

  cloudwatch_log_groups = {
    jobs = module.cloudwatch.log_group_jobs.name,
    web  = module.cloudwatch.log_group_web.name,
  }
}

module "iam" {
  source = "../iam"

  assets_bucket_arn            = module.s3.assets_bucket.arn
  cloudwatch_log_groups        = [module.cloudwatch.log_group_jobs.arn, module.cloudwatch.log_group_web.arn]
  deployment_bucket            = module.codesuite.deployment_bucket.arn
  ecr_repository               = module.ecr.repository.arn
  enviroment_variables_secrets = [module.secretsmanager.secret_dynamic.arn, module.secretsmanager.secret_static.arn]
  name_prefix                  = local.name_prefix
}

module "load_balancer" {
  source = "../load_balancer"

  certificate_arn        = module.acm_us_west_2.certificate_arn
  health_check_path_jobs = "/status"
  health_check_path_web  = "/health"
  name_prefix            = local.name_prefix
  security_group         = module.security_groups.load_balancer.id
  service_port           = local.service_port
  subnets                = [for subnet in module.vpc.public_subnets : subnet.id]
  vpc_id                 = module.vpc.vpc.id
}

module "rds" {
  source = "../rds"

  name_prefix    = local.name_prefix
  security_group = module.security_groups.rds.id
  subnet_group   = module.vpc.private_subnet_group.name
}

module "route53" {
  source = "../route53"

  cdn_assets_dns_name       = module.cloudfront.cdn_assets.domain_name
  cdn_assets_dns_zone_id    = module.cloudfront.cdn_assets.hosted_zone_id
  cdn_tiles_dns_name        = module.cloudfront.cdn_tiles.domain_name
  cdn_tiles_dns_zone_id     = module.cloudfront.cdn_tiles.hosted_zone_id
  domain_apex               = var.domain
  domain_cdn_assets         = local.domain_assets_cdn
  domain_cdn_tiles          = local.domain_tiles_cdn
  load_balancer_dns_name    = module.load_balancer.load_balancer.dns_name
  load_balancer_dns_zone_id = module.load_balancer.load_balancer.zone_id
  name_prefix               = local.name_prefix
}

module "s3" {
  source = "../s3"

  cloudfront_distributions = [module.cloudfront.cdn_assets.arn, module.cloudfront.cdn_tiles.arn]
  name_prefix              = local.name_prefix
}

module "secretsmanager" {
  source = "../secretsmanager"

  asset_bucket      = module.s3.assets_bucket.bucket
  asset_host        = module.route53.cdn_assets_record.fqdn
  database_endpoint = module.rds.database_endpoint
  database_password = module.rds.database_password
  database_username = module.rds.database_username
  name_prefix       = local.name_prefix
  smtp_password     = module.iam.smtp_password
  smtp_username     = module.iam.smtp_username
  tiles_host        = module.route53.cdn_tiles_record.fqdn
}

module "security_groups" {
  source = "../security_groups"

  name_prefix  = local.name_prefix
  service_port = local.service_port
  vpc_id       = module.vpc.vpc.id
}

module "ses" {
  source = "../ses"

  domain       = var.domain
  route53_zone = module.route53.zone.zone_id
}

module "vpc" {
  source = "../vpc"

  name_prefix = local.name_prefix
}
