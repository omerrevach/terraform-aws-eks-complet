terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  vpc_tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
  
  # Combine default addon settings with user-provided settings
  aws_lb_controller_settings = concat(
    [{ name = "vpcId", value = module.vpc.vpc_id }],
    var.aws_load_balancer_controller_settings
  )
  
  external_dns_settings = concat(
    [
      { name = "policy", value = "sync" },
      { name = "domainFilters[0]", value = var.external_dns_domain },
      { name = "txtOwnerId", value = var.external_dns_txt_owner_id },
      { name = "sources[0]", value = "service" },
      { name = "sources[1]", value = "ingress" }
    ],
    var.external_dns_settings
  )
  
  external_secrets_settings = concat(
    [{ name = "region", value = var.region }],
    var.external_secrets_settings
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.cluster_name
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway && var.enable_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery"                    = var.cluster_name
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = local.vpc_tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  control_plane_subnet_ids                 = module.vpc.public_subnets
  enable_irsa                              = var.enable_irsa
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  cluster_endpoint_private_access          = var.cluster_endpoint_private_access
  cluster_endpoint_public_access           = var.cluster_endpoint_public_access

  cluster_addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
    aws-ebs-csi-driver     = { most_recent = true }
    vpc-cni = {
        most_recent = true
        preserve    = true
    }
  }

  eks_managed_node_groups = {
    general = {
      instance_type = var.instance_type
      min_size      = var.node_min_size
      max_size      = var.node_max_size
      desired_size  = var.node_desired_size

      enable_monitoring = var.enable_detailed_monitoring

      tags = merge(
        var.tags,
        {
          "karpenter.sh/discovery" = var.cluster_name
        }
      )

      labels = {
        role = "general"
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = var.tags
}

# Create time-based resources to enforce ordering
resource "time_sleep" "after_eks" {
  depends_on = [module.eks]
  create_duration = lookup(var.addon_timeouts, "after_eks", "10s")
}

module "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.15.1"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Only enable the AWS Load Balancer Controller
  enable_aws_load_balancer_controller = true

  aws_load_balancer_controller = {
    set = local.aws_lb_controller_settings
  }

  depends_on = [
    time_sleep.after_eks
  ]
}

resource "time_sleep" "after_lb_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  
  depends_on = [module.aws_load_balancer_controller]
  create_duration = lookup(var.addon_timeouts, "after_lb_controller", "10s")
}

module "external_dns" {
  count = var.enable_external_dns ? 1 : 0
  
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.15.1"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Only enable External DNS
  enable_external_dns = true
  external_dns_route53_zone_arns = var.external_dns_route53_zone_arns

  external_dns = {
    set = local.external_dns_settings
  }

  depends_on = [
    time_sleep.after_lb_controller
  ]
}

resource "time_sleep" "after_external_dns" {
  count = var.enable_external_dns ? 1 : 0
  
  depends_on = [module.external_dns]
  create_duration = lookup(var.addon_timeouts, "after_external_dns", "10s")
}

module "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.15.1"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Only enable External Secrets
  enable_external_secrets = true

  external_secrets = {
    set = local.external_secrets_settings
  }

  depends_on = [
    time_sleep.after_external_dns
  ]
}

resource "time_sleep" "after_external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  
  depends_on = [module.external_secrets]
  create_duration = lookup(var.addon_timeouts, "after_external_secrets", "10s")
}

module "argocd" {
  count = var.enable_argocd ? 1 : 0
  
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.15.1"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Only enable ArgoCD
  enable_argocd = true

  argocd = merge(
    {
      namespace     = "argocd"
      chart_version = "5.51.6"
      repository    = "https://argoproj.github.io/argo-helm"
      values = [
        <<-EOF
        server:
          extraArgs:
            - --insecure
          service:
            type: ClusterIP
            servicePortHttp: 8080
          ingress:
            enabled: true
            ingressClassName: alb
            annotations:
              alb.ingress.kubernetes.io/scheme: internet-facing
              alb.ingress.kubernetes.io/target-type: ip
              alb.ingress.kubernetes.io/group.name: addons-group
              alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
              alb.ingress.kubernetes.io/backend-protocol: HTTP
              alb.ingress.kubernetes.io/healthcheck-path: /
              alb.ingress.kubernetes.io/success-codes: "200-399"
              alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=120
              alb.ingress.kubernetes.io/ssl-redirect: '443'
              alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:${var.region}:${data.aws_caller_identity.current.account_id}:certificate/${var.acm_cert_id}
              external-dns.alpha.kubernetes.io/hostname: ${var.argocd_domain}
            hosts:
              - ${var.argocd_domain}
            path: /
            pathType: Prefix
          configs:
            cm:
              url: https://${var.argocd_domain}
            params:
              server.insecure: "true"
        EOF
      ]
    },
    var.argocd_settings
  )

  depends_on = [
    time_sleep.after_external_secrets
  ]
}