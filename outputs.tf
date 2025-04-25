output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "argocd_url" {
  description = "ArgoCD URL"
  value       = var.enable_argocd ? "https://argocd.${var.domain_name}" : null
}

output "load_balancer_controller_enabled" {
  description = "Whether AWS Load Balancer Controller is enabled"
  value       = var.enable_aws_load_balancer_controller
}

output "external_dns_enabled" {
  description = "Whether External DNS is enabled"
  value       = var.enable_external_dns
}

output "external_secrets_enabled" {
  description = "Whether External Secrets is enabled"
  value       = var.enable_external_secrets
}

output "node_group_arns" {
  description = "ARNs of the EKS node groups"
  value       = module.eks.eks_managed_node_groups
}