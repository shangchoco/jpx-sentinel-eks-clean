# --------------------------------------------------
# Amazon EKS Cluster
# --------------------------------------------------
#
# 목적:
# 기존 ECS Fargate 환경을 Kubernetes(EKS) 환경으로 확장
# 기존 VPC, RDS, ECR 자원 재사용
#
# 새로 만드는 것:
# EKS Cluster, EKS Node Group, ALB 컨트롤러용 IAM Role
# --------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "jpx-sentinel-eks"
  cluster_version = "1.31"

  # 클러스터 접근 설정
  cluster_endpoint_public_access = true

  # IRSA (IAM Roles for Service Accounts) 활성화
  enable_irsa = true

  # VPC 네트워크 설정
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # ECR 이미지 접근 권한
  node_iam_role_additional_policies = {
    ecr_readonly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  # 클러스터 관리자 권한
  enable_cluster_creator_admin_permissions = true

  # --------------------------------------------------
  # 필수 애드온 (Add-ons) 설정
  # --------------------------------------------------
  cluster_addons = {
    vpc-cni    = { most_recent = true }
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
  }

  # --------------------------------------------------
  # Managed Node Group
  # --------------------------------------------------
  # [참고] 비용 절감을 원하실 경우 아래 값을 0으로 조정 후 
  # terraform apply를 실행하면 노드가 삭제됩니다.
  # --------------------------------------------------
  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2_x86_64"
      instance_types = ["t3.medium"]
      
      min_size     = 2
      desired_size = 3
      max_size     = 3
    }
  }

  tags = {
    Environment = "dev"
    Project     = "jpx-sentinel-eks"
    ManagedBy   = "terraform"
  }
}

# --------------------------------------------------
# AWS Load Balancer Controller IAM Role
# --------------------------------------------------
# ALB 생성을 위해 EKS OIDC와 연동된 IAM Role 생성
# --------------------------------------------------
module "lb_controller_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"
  
  role_name = "aws-load-balancer-controller"
  
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  role_policy_arns = {
    policy = "arn:aws:iam::264143700981:policy/AWSLoadBalancerControllerIAMPolicy"
  }
}