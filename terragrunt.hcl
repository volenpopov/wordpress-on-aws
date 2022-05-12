locals {
  region = "us-east-1"

  default_tags = {
    App     = "wordpress"
    Creator = "terraform"
  }
}

generate "provider" {
  path      = "providers.gitignore.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.4.0"
    }
  }
}

provider "aws" {
  region = "${local.region}"
 
  default_tags {
    tags = {
        App     = "${local.default_tags.App}"
        Creator = "${local.default_tags.Creator}"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    region = local.region
    # TODO: make the bucket name UNIQUE and dynamically generated using you AWS account name or ID
    bucket         = "terraform-state-wordpress-12345"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  generate = {
    path      = "backend.gitignore.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  region = local.region
}