resource "helm_release" "alb_controller" {
    name = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart = "aws-load-balancer-controller"
    version = "2.5.0"
    namespace = "kube-system"
    values = [
        "values.yaml"
    ]

    depends_on = [
        aws_eks_node_group.scoutflow_eks_node_group
    ]

    set {
        name = "scoutflow_eks_cluster"
        value = aws_eks_cluster.scoutflow_eks_cluster.name
    }

    set {
        name = "serviceAccount.create"
        value = "true"
    }

    set {
        name = "serviceAccount.name"
        value = "aws-load-balancer-controller"
    }

    set {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = aws_iam_role.alb_controller_role.arn
    }

    set {
        name  = "vpcId"
        value = aws_vpc.scoutflow_vpc.id
    }
}