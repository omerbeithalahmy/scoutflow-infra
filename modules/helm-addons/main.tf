# Helm Addons Module
# Deploys AWS Load Balancer Controller, ArgoCD, and Observability Stack

# ============================================
# AWS Load Balancer Controller - IAM Policy
# ============================================

# Fetch the official ALB Controller IAM Policy
data "http" "alb_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json"
}

# Create the IAM Policy for ALB Controller
resource "aws_iam_policy" "alb_controller_policy" {
  name_prefix = "${var.project_name}-${var.environment}-alb-controller-"
  description = "IAM Policy for AWS Load Balancer Controller - ${var.environment}"
  policy      = data.http.alb_iam_policy.response_body

  tags = {
    Environment = var.environment
  }
}

# Create IRSA Role for ALB Controller
resource "aws_iam_role" "alb_controller_role" {
  name_prefix = "${var.project_name}-${var.environment}-alb-controller-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${var.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

# ============================================
# AWS Load Balancer Controller - Helm Chart
# ============================================

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.alb_controller_version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller_role.arn
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}

# ============================================
# ArgoCD - GitOps Continuous Delivery
# ============================================

resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = var.argocd_version
}

# ============================================
# Observability - Prometheus & Grafana
# ============================================

# Random password for Grafana admin
resource "random_password" "grafana_admin_password" {
  count   = var.enable_monitoring ? 1 : 0
  length  = 16
  special = true
}

resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_monitoring ? 1 : 0

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = var.monitoring_version

  set_sensitive {
    name  = "grafana.adminPassword"
    value = random_password.grafana_admin_password[0].result
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }
}

# ============================================
# Cluster Autoscaler (Optional)
# ============================================

# IAM Policy for Cluster Autoscaler
data "aws_iam_policy_document" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeImages",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-cluster-autoscaler-"
  description = "IAM Policy for Cluster Autoscaler - ${var.environment}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler[0].json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-cluster-autoscaler-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
            "${var.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  role       = aws_iam_role.cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.cluster_autoscaler_version

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler[0].arn
  }
}

data "aws_region" "current" {}
