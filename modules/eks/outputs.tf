output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA certificate for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group EKS created for the control plane and nodes. Allow it in downstream SGs (e.g. the database)."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider, for IRSA roles."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "node_role_arn" {
  description = "IAM role ARN used by the managed node groups."
  value       = aws_iam_role.node.arn
}
