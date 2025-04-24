variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "enable_irsa" {
  description = "Enable IAM roles for service accounts"
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Enable cluster creator admin permissions"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type for node groups"
  type        = string
  default     = "m5.large"
}

variable "node_min_size" {
  description = "Minimum number of nodes in node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in node group"
  type        = number
  default     = 5
}

variable "node_desired_size" {
  description = "Desired number of nodes in node group"
  type        = number
  default     = 3
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for EC2 instances in node group"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# AWS Load Balancer Controller variables
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

# External DNS variables
variable "enable_external_dns" {
  description = "Enable External DNS"
  type        = bool
  default     = true
}

variable "external_dns_domain" {
  description = "Domain to use for External DNS"
  type        = string
  default     = ""
}

variable "external_dns_txt_owner_id" {
  description = "TXT record owner ID for External DNS"
  type        = string
  default     = ""
}

variable "external_dns_route53_zone_arns" {
  description = "List of Route53 zone ARNs for External DNS"
  type        = list(string)
  default     = []
}

# External Secrets variables
variable "enable_external_secrets" {
  description = "Enable External Secrets"
  type        = bool
  default     = true
}

# ArgoCD variables
variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = true
}

variable "argocd_domain" {
  description = "Domain for ArgoCD ingress"
  type        = string
  default     = ""
}

variable "acm_cert_id" {
  description = "ACM certificate ID for ArgoCD"
  type        = string
  default     = ""
}

# Add-on timeouts
variable "addon_timeouts" {
  description = "Map of timeouts for add-ons"
  type        = map(string)
  default = {
    after_eks            = "10s"
    after_lb_controller  = "10s"
    after_external_dns   = "10s"
    after_external_secrets = "10s"
  }
}

# Additional AWS Load Balancer Controller settings
variable "aws_load_balancer_controller_settings" {
  description = "Additional settings for AWS Load Balancer Controller"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

# Additional External DNS settings
variable "external_dns_settings" {
  description = "Additional settings for External DNS"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

# Additional External Secrets settings
variable "external_secrets_settings" {
  description = "Additional settings for External Secrets"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

# Additional ArgoCD settings
variable "argocd_settings" {
  description = "Additional settings for ArgoCD"
  type        = map(string)
  default     = {}
}