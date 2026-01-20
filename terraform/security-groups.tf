resource "aws_security_group" "cluster" {
    name = "${var.project_name}-cluster-sg"
    description = "Security group for EKS cluster"
    vpc_id = aws_vpc.scoutflow_vpc.id

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-cluster-sg"
    }
}

resource "aws_security_group" "node" {
    name = "${var.project_name}-node-sg"
    description = "Security group for EKS nodes"
    vpc_id = aws_vpc.scoutflow_vpc.id

    ingress {
        description = "Allow node to node communication"
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = true
    }

    ingress {
        description = "Allow control plane to communicate with nodes"
        from_port = 1025
        to_port = 65535
        protocol = "tcp"
        security_groups = [aws_security_group.cluster.id]
    }

    ingress {
        description = "Allow control plane (Extension API) to communicate with nodes"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        security_groups = [aws_security_group.cluster.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-node-sg"
        "kubernetes.io/cluster/${var.project_name}-cluster" = "owned"
    }
}
    