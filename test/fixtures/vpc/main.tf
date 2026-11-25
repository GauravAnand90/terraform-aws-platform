terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "name" {
  description = "Unique name for this test run."
  type        = string
}

variable "region" {
  description = "Region to test in."
  type        = string
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "terraform-aws-platform"
      Purpose = "terratest"
      TestRun = var.name
    }
  }
}

module "vpc" {
  source = "../../../modules/vpc"

  name                    = var.name
  cidr_block              = "10.99.0.0/16"
  azs                     = ["${var.region}a", "${var.region}b"]
  single_nat_gateway      = true
  flow_log_retention_days = 1
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs."
  value       = module.vpc.database_subnet_ids
}
