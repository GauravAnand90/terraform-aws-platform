variable "environment" {
  description = "Environment name (dev, prod)."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}

variable "cost_center" {
  description = "Cost allocation tag value."
  type        = string
  default     = "platform"
}

variable "azs" {
  description = "Availability zones, pinned explicitly so the network never changes shape when AWS adds a zone."
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR. Keep environments non-overlapping so they can be peered later."
  type        = string
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across AZs (dev cost saving)."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "eks_public_endpoint" {
  description = "Expose the EKS API publicly."
  type        = bool
  default     = false
}

variable "eks_public_access_cidrs" {
  description = "CIDRs allowed to the public EKS API endpoint."
  type        = list(string)
  default     = []
}

variable "eks_admin_principal_arns" {
  description = "IAM roles granted cluster-admin. Set via TF_VAR_eks_admin_principal_arns or tfvars."
  type        = list(string)
  default     = []
}

variable "eks_node_groups" {
  description = "Managed node groups; passed straight to modules/eks."
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size_gb   = optional(number, 50)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))
}

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 30
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL version."
  type        = string
}

variable "aurora_instance_class" {
  description = "Aurora instance class, or db.serverless."
  type        = string
}

variable "aurora_instance_count" {
  description = "Writer + reader instances."
  type        = number
}

variable "aurora_serverless_v2_scaling" {
  description = "ACU range when using db.serverless."
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = null
}

variable "aurora_backup_retention_days" {
  description = "Automated backup retention."
  type        = number
  default     = 7
}

variable "aurora_deletion_protection" {
  description = "Block accidental deletion of the Aurora cluster."
  type        = bool
  default     = true
}

variable "aurora_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (dev only)."
  type        = bool
  default     = false
}

variable "aurora_monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (1, 5, 10, 15, 30 or 60)."
  type        = number
  default     = 60
}
