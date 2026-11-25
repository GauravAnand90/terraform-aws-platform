provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

locals {
  name = "platform-${var.environment}"

  tags = {
    Project     = "terraform-aws-platform"
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "github.com/GauravAnand90/terraform-aws-platform"
    CostCenter  = var.cost_center
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  cidr_block         = var.vpc_cidr
  azs                = var.azs
  single_nat_gateway = var.single_nat_gateway
  cluster_name       = local.name
}

module "eks" {
  source = "../../modules/eks"

  cluster_name           = local.name
  kubernetes_version     = var.kubernetes_version
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  endpoint_public_access = var.eks_public_endpoint
  public_access_cidrs    = var.eks_public_access_cidrs
  admin_principal_arns   = var.eks_admin_principal_arns
  node_groups            = var.eks_node_groups
  log_retention_days     = var.log_retention_days
}

module "aurora" {
  source = "../../modules/rds-aurora"

  name                       = local.name
  engine_version             = var.aurora_engine_version
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.database_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = var.aurora_instance_class
  instance_count             = var.aurora_instance_count
  serverless_v2_scaling      = var.aurora_serverless_v2_scaling
  backup_retention_days      = var.aurora_backup_retention_days
  deletion_protection        = var.aurora_deletion_protection
  skip_final_snapshot        = var.aurora_skip_final_snapshot
  monitoring_interval        = var.aurora_monitoring_interval
}
