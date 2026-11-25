output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "aurora_writer_endpoint" {
  description = "Aurora writer endpoint."
  value       = module.aurora.writer_endpoint
}

output "aurora_secret_arn" {
  description = "Secrets Manager ARN for the Aurora master credentials."
  value       = module.aurora.master_user_secret_arn
}
