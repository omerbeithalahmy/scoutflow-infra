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