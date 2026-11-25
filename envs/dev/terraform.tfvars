# dev: optimized for cost. Single NAT, 2 AZs, spot nodes, Serverless v2 Aurora that scales near zero.
environment = "dev"
azs         = ["us-west-2a", "us-west-2b"]
vpc_cidr    = "10.10.0.0/16"

single_nat_gateway = true

kubernetes_version  = "1.33"
eks_public_endpoint = false

eks_node_groups = {
  general = {
    instance_types = ["m6i.large", "m6a.large", "m5.large"] # several types = better spot availability
    capacity_type  = "SPOT"
    min_size       = 1
    max_size       = 4
    desired_size   = 2
  }
}

log_retention_days = 7

aurora_engine_version        = "16.4"
aurora_instance_class        = "db.serverless"
aurora_instance_count        = 1
aurora_serverless_v2_scaling = { min_capacity = 0.5, max_capacity = 2 }
aurora_backup_retention_days = 1
aurora_deletion_protection   = true # set false in a PR before tearing dev down
aurora_skip_final_snapshot   = true
