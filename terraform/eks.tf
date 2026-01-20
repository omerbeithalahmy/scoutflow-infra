resource "aws_eks_cluster" "scoutflow_eks_cluster" {
    name = var.eks_cluster_name
    role_arn = aws_iam_role.cluster.arn
    version = "1.28"

    vpc_config {
        subnet_ids = [
            aws_subnet.public_1.id, 
            aws_subnet.public_2.id,
            aws_subnet.private_1.id,
            aws_subnet.private_2.id,
        ]
        endpoint_private_access = true
        endpoint_public_access = true
        security_group_ids = [aws_security_group.cluster.id]
    }

    depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

resource "aws_eks_node_group" "scoutflow_eks_node_group" {
    cluster_name = aws_eks_cluster.scoutflow_eks_cluster.name
    node_group_name = "${var.project_name}-node-group"
    node_role_arn = aws_iam_role.node.arn

    subnet_ids = [
        aws_subnet.private_1.id,
        aws_subnet.private_2.id,
    ]

    scaling_config {
        desired_size = var.node_count
        min_size = 1
        max_size = var.node_count + 1
    }

    instance_types = [var.node_instance_type]
    capacity_type = "ON_DEMAND"

    depends_on = [
        aws_iam_role_policy_attachment.node_worker_policy,
        aws_iam_role_policy_attachment.node_cni_policy,
        aws_iam_role_policy_attachment.node_ecr_policy,
    ]

    tags = {
        Name = "${var.project_name}-managed-node"
    }
}
    
    