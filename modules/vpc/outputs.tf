output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (load balancers, NAT gateways)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (EKS nodes and pods)."
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the isolated database subnets (no internet route)."
  value       = aws_subnet.database[*].id
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateways, useful for allow-listing egress with partners."
  value       = aws_eip.nat[*].public_ip
}
