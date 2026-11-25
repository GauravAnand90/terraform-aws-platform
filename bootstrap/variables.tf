variable "region" {
  description = "Region for the state bucket."
  type        = string
  default     = "us-west-2"
}

variable "state_bucket_prefix" {
  description = "Prefix for the state bucket; the account ID is appended to keep it globally unique."
  type        = string
  default     = "tfstate-platform"
}

variable "github_owner" {
  description = "GitHub user or org that owns the repo."
  type        = string
  default     = "GauravAnand90"
}

variable "github_repo" {
  description = "Repository allowed to assume the CI roles."
  type        = string
  default     = "terraform-aws-platform"
}

variable "github_environments" {
  description = "GitHub environments allowed to assume the apply role."
  type        = list(string)
  default     = ["dev", "prod"]
}
