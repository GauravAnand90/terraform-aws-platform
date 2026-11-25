variable "name" {
  description = "Name prefix for all VPC resources (e.g. platform-dev)."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR, e.g. 10.10.0.0/16."
  }
}

variable "azs" {
  description = "Availability zones to spread subnets across. Use at least 2 (3 recommended for prod)."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least two availability zones for high availability."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (cheaper, for dev) instead of one per AZ (resilient, for prod)."
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Optional EKS cluster name. When set, subnets get the tags EKS and the AWS Load Balancer Controller use for discovery."
  type        = string
  default     = null
}

variable "flow_log_retention_days" {
  description = "Retention in days for VPC flow logs in CloudWatch."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
