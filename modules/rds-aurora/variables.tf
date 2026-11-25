variable "name" {
  description = "Cluster identifier and name prefix."
  type        = string
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version (e.g. 16.4)."
  type        = string
}

variable "vpc_id" {
  description = "VPC the cluster runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Isolated database subnet IDs (at least two AZs)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 5432 (e.g. the EKS cluster SG)."
  type        = list(string)
  default     = []
}

variable "database_name" {
  description = "Name of the initial database."
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master username. The password is generated and rotated by RDS in Secrets Manager."
  type        = string
  default     = "platform_admin"
}

variable "instance_class" {
  description = "Instance class for writer and readers. Use db.serverless with serverless_v2_scaling for Serverless v2."
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of instances: 1 writer plus (n-1) readers. Use 2+ in prod for fast failover."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 15
    error_message = "instance_count must be between 1 and 15."
  }
}

variable "serverless_v2_scaling" {
  description = "Serverless v2 capacity range in ACUs. Only used when instance_class is db.serverless."
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = null
}

variable "backup_retention_days" {
  description = "Days of automated backups (point-in-time restore window)."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Block accidental deletion. Always true in prod."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. Only for throwaway dev clusters."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds. OS-level metrics (CPU steal, memory, IO) that CloudWatch alone doesn't show."
  type        = number
  default     = 60

  validation {
    condition     = contains([1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of 1, 5, 10, 15, 30, 60."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
