# prod: optimized for resilience. NAT per AZ, 3 AZs, on-demand nodes, provisioned Aurora writer + reader.
environment = "prod"
azs         = ["us-west-2a", "us-west-2b", "us-west-2c"]
vpc_cidr    = "10.20.0.0/16"

single_nat_gateway = false

kubernetes_version  = "1.33"
eks_public_endpoint = false

eks_node_groups = {
  general = {
    instance_types = ["m6i.xlarge"]
    capacity_type  = "ON_DEMAND"
    min_size       = 3 # one per AZ minimum
    max_size       = 12
    desired_size   = 3
  }
  system = {
    instance_types = ["m6i.large"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 3
    desired_size   = 2
    labels         = { workload = "system" }
    taints = [{
      key    = "CriticalAddonsOnly"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
  }
}

log_retention_days = 90

aurora_engine_version        = "16.4"
aurora_instance_class        = "db.r6g.large"
aurora_instance_count        = 2
aurora_backup_retention_days = 14
aurora_deletion_protection   = true
aurora_skip_final_snapshot   = false
