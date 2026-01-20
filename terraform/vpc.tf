#Custom VPC
resource "aws_vpc" "scoutflow_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "${var.project_name}_vpc"
    }
}

#Internet Gateway
resource "aws_internet_gateway" "scoutflow_igw" {
    vpc_id = aws_vpc.scoutflow_vpc.id

    tags = {
        Name = "${var.project_name}_igw"
    }
}

#Get List of AZs
data "aws_availability_zones" "available" {
    state = "available"
}

#Public Subnets
resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.scoutflow_vpc.id
    cidr_block = "141.0.0.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        Name = "${var.project_name}_public_1" 
        "kubernetes.io/role/elb" = "1"
    }
}

resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.scoutflow_vpc.id
    cidr_block = "141.0.1.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]

    tags = {
        Name = "${var.project_name}_public_2" 
        "kubernetes.io/role/elb" = "1"
    }
}

