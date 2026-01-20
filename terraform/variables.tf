variable "region" {
    description = "AWS region"
    type = string
    default = "us-east-1"
}   

variable "vpc_cidr" {
    description = "VPC CIDR block"
    type = string
    default = "141.0.0.0/16"
}

variable "project_name" {
    description = "Project name"
    type = string
    default = "scoutflow"
}   

variable "eks_cluster_name" {
    description = "EKS cluster name"
    type = string
    default = "scoutflow-eks-cluster"
}

variable "node_instance_type" {
    description = "EC2 instance type for EKS nodes"
    type = string
    default = "t2.medium"
}

variable "node_count" {
    description = "Number of EKS nodes"
    type = number
    default = 2
}
