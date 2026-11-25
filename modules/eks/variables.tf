variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version for the control plane (e.g. 1.33). Upgrade one minor version at a time."
  type        = string
}

variable "vpc_id" {
  description = "VPC the cluster runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and worker nodes."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API publicly. Keep false in prod and reach the API over VPN or a bastion."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint, when it is enabled."
  type        = list(string)
  default     = []
}

variable "admin_principal_arns" {
  description = "IAM role or user ARNs granted cluster-admin through EKS access entries."
  type        = list(string)
  default     = []
}

variable "node_groups" {
  description = "Managed node groups keyed by name."
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

  validation {
    condition     = alltrue([for ng in values(var.node_groups) : contains(["ON_DEMAND", "SPOT"], ng.capacity_type)])
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "control_plane_log_types" {
  description = "Control plane log types to send to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "log_retention_days" {
  description = "Retention in days for control plane logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
