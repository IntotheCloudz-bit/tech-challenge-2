output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.tech2.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.tech2.endpoint
}

output "aws_region" {
  description = "AWS region used by Terraform"
  value       = "us-east-1"
}