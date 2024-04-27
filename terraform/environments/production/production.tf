terraform {
  backend "s3" {
    bucket  = "shanet-terraform-backend"
    key     = "pirep/production.tfstate"
    profile = "personal"
    region  = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.47.0"
    }
  }
}

variable "aws_profile" { default = "personal" }

provider "aws" {
  profile = var.aws_profile
  region  = "us-west-2"
}

provider "aws" {
  alias   = "us_east_1"
  profile = var.aws_profile
  region  = "us-east-1"
}

module "project" {
  source = "../../modules/project"

  domain     = "pirep.io"
  enviroment = "production"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}
