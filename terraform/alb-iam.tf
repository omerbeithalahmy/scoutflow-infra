# ALB Controller IAM Role - IRSA (IAM Role for Service Accounts)
# Documentation: https://kubernetes-sigs.github.io/aws-load-balancer-controller/

# Fetch the official ALB Controller IAM Policy
data "http" "alb_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json"
}

# Create the IAM Policy for ALB Controller
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.project_name}-alb-controller-policy"
  description = "IAM Policy for AWS Load Balancer Controller"
  policy      = data.http.alb_iam_policy.response_body
}

# Create IRSA Role for ALB Controller
resource "aws_iam_role" "alb_controller_role" {
  name = "${var.project_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}