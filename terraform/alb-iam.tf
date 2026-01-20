# Official IAM Policy for ALB
data "http" "alb_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json"
}

# Create the Policy Resource
resource "aws_iam_policy" "alb_controller_policy" {
    name = "${var.project_name}-alb-controller-policy"
    description = "Policy for ALB Controller"
    policy = data.http.alb_iam_policy.response_body
}

# Create the Role
resource "aws_iam_role" "alb_controller_role" {
    name = "${var.project_name}-alb-controller-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
    role = aws_iam_role.alb_controller_role.name
    policy_arn = aws_iam_policy.alb_controller_policy.arn
}
    