# AWS EKS Production Cluster

A Terraform module to create a production-ready Amazon EKS cluster with essential managed add-ons properly ordered for dependency management.

## Features

- Production-grade Amazon EKS cluster with managed node groups
- Properly configured VPC with public and private subnets
- Core add-ons with correct dependency ordering:
  1. AWS Load Balancer Controller
  2. External DNS
  3. External Secrets
  4. ArgoCD
- IAM roles for service accounts (IRSA)
- Configurable node groups and cluster parameters
- Comprehensive tagging system

## Usage

### Basic Example

```hcl
module "eks_production_cluster" {
  source = "example/eks-production-cluster/aws"
  version = "1.0.0"
  
  region         = "us-west-2"
  cluster_name   = "production-eks"
  cluster_version = "1.28"

  # VPC configuration
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  # Node group configuration
  instance_type     = "m5.large"
  node_min_size     = 3
  node_max_size     = 5
  node_desired_size = 3
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "example"
  }
}
```

### Complete Example with All Add-ons

```hcl
module "eks_production_cluster" {
  source  = "example/eks-production-cluster/aws"
  version = "1.0.0"
  
  region         = "us-west-2"
  cluster_name   = "production-eks"
  cluster_version = "1.28"

  # VPC configuration
  vpc_cidr              = "10.0.0.0/16"
  private_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway    = true
  single_nat_gateway    = false  # High availability setup with NAT gateway per AZ

  # EKS configuration
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_private_access          = true
  cluster_endpoint_public_access           = true

  # Node group configuration
  instance_type       = "m5.large"
  node_min_size       = 3
  node_max_size       = 10
  node_desired_size   = 3
  enable_detailed_monitoring = true

  # Add-on configuration
  enable_aws_load_balancer_controller = true
  enable_external_dns                 = true
  enable_external_secrets             = true
  enable_argocd                       = true

  # External DNS configuration
  external_dns_domain        = "example.com"
  external_dns_txt_owner_id  = "eks-production"
  external_dns_route53_zone_arns = ["arn:aws:route53:::hostedzone/ZABCDEFGHIJKLM"]

  # ArgoCD configuration
  argocd_domain = "argocd.example.com"
  acm_cert_id   = "12345678-1234-1234-1234-123456789012"

  # Add-on timeouts for dependency management
  addon_timeouts = {
    after_eks              = "20s"
    after_lb_controller    = "30s"
    after_external_dns     = "20s"
    after_external_secrets = "20s"
  }

  # Additional add-on settings
  aws_load_balancer_controller_settings = [
    { name = "region", value = "us-west-2" },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" }
  ]

  # Global tagging
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Team        = "platform"
    CostCenter  = "12345"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | ~> 5.0 |
| helm | >= 2.7.0 |
| kubectl | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| helm | >= 2.7.0 |
| kubectl | ~> 1.14 |
| time | n/a |

## Resources

| Name | Type |
|------|------|
| [module.vpc](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) | module |
| [module.eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) | module |
| [module.aws_load_balancer_controller](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest) | module |
| [module.external_dns](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest) | module |
| [module.external_secrets](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest) | module |
| [module.argocd](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest) | module |
| [time_sleep.after_eks](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.after_lb_controller](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.after_external_dns](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.after_external_secrets](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS region | `string` | `"us-west-2"` | no |
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| cluster_version | Kubernetes version to use for the EKS cluster | `string` | `"1.28"` | no |
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]` | no |
| enable_nat_gateway | Should be true if you want to provision NAT Gateways for private subnets | `bool` | `true` | no |
| single_nat_gateway | Should be true if you want to provision a single shared NAT Gateway for all private subnets | `bool` | `false` | no |
| enable_irsa | Enable IAM roles for service accounts | `bool` | `true` | no |
| enable_cluster_creator_admin_permissions | Enable cluster creator admin permissions | `bool` | `true` | no |
| cluster_endpoint_private_access | Enable private access to the cluster endpoint | `bool` | `true` | no |
| cluster_endpoint_public_access | Enable public access to the cluster endpoint | `bool` | `true` | no |
| instance_type | EC2 instance type for node groups | `string` | `"m5.large"` | no |
| node_min_size | Minimum number of nodes in node group | `number` | `2` | no |
| node_max_size | Maximum number of nodes in node group | `number` | `5` | no |
| node_desired_size | Desired number of nodes in node group | `number` | `3` | no |
| enable_detailed_monitoring | Enable detailed monitoring for EC2 instances in node group | `bool` | `true` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |
| enable_aws_load_balancer_controller | Enable AWS Load Balancer Controller | `bool` | `true` | no |
| enable_external_dns | Enable External DNS | `bool` | `true` | no |
| external_dns_domain | Domain to use for External DNS | `string` | `""` | no |
| external_dns_txt_owner_id | TXT record owner ID for External DNS | `string` | `""` | no |
| external_dns_route53_zone_arns | List of Route53 zone ARNs for External DNS | `list(string)` | `[]` | no |
| enable_external_secrets | Enable External Secrets | `bool` | `true` | no |
| enable_argocd | Enable ArgoCD | `bool` | `true` | no |
| argocd_domain | Domain for ArgoCD ingress | `string` | `""` | no |
| acm_cert_id | ACM certificate ID for ArgoCD | `string` | `""` | no |
| addon_timeouts | Map of timeouts for add-ons | `map(string)` | `{ "after_eks": "10s", "after_lb_controller": "10s", "after_external_dns": "10s", "after_external_secrets": "10s" }` | no |
| aws_load_balancer_controller_settings | Additional settings for AWS Load Balancer Controller | `list(object({ name = string, value = string }))` | `[]` | no |
| external_dns_settings | Additional settings for External DNS | `list(object({ name = string, value = string }))` | `[]` | no |
| external_secrets_settings | Additional settings for External Secrets | `list(object({ name = string, value = string }))` | `[]` | no |
| argocd_settings | Additional settings for ArgoCD | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| private_subnets | List of private subnet IDs |
| public_subnets | List of public subnet IDs |
| cluster_id | EKS cluster ID |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| oidc_provider_arn | The ARN of the OIDC Provider |
| region | AWS region |
| argocd_url | ArgoCD URL |

## Add-on Dependency Management

This module ensures proper ordering of add-on installation through a combination of separate module calls and time-based dependencies:

1. The EKS cluster is created first
2. A small delay ensures the cluster is fully operational
3. AWS Load Balancer Controller is installed
4. Another delay ensures the controller is running
5. External DNS is installed
6. Another delay ensures External DNS is running
7. External Secrets is installed
8. Finally, after a delay, ArgoCD is installed

This approach guarantees that each component has its dependencies properly initialized before installation.

## Add-on Compatibility

| Add-on | Purpose | Dependencies |
|--------|---------|--------------|
| AWS Load Balancer Controller | Manages AWS ALB/NLB for Kubernetes services | EKS Cluster |
| External DNS | Synchronizes Kubernetes Ingress resources with DNS providers | AWS Load Balancer Controller |
| External Secrets | Synchronizes Kubernetes secrets with external secret stores | None, but installed after External DNS for consistency |
| ArgoCD | GitOps continuous delivery tool for Kubernetes | All other add-ons (for managing app deployments) |

## Best Practices

This module implements several EKS best practices:

- **High Availability**: Deploys across multiple Availability Zones
- **Security**: Proper IAM permissions and security group configurations
- **Scaling**: Configurable node groups with auto-scaling capability
- **Networking**: Separate public and private subnets with appropriate routing
- **Add-ons**: Core add-ons for production environments
- **Monitoring**: Detailed monitoring enabled by default

## Authors

Module is maintained by [Omer Revach]

## License

Apache 2 Licensed. See LICENSE for full details.