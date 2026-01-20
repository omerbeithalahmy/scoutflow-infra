# Custom VPC
resource "aws_vpc" "scoutflow_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "${var.project_name}_vpc"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "scoutflow_igw" {
    vpc_id = aws_vpc.scoutflow_vpc.id

    tags = {
        Name = "${var.project_name}_igw"
    }
}

# Get List of AZs
data "aws_availability_zones" "available" {
    state = "available"
}

# Public Subnets
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

# Private Subnets
resource "aws_subnet" "private_1" {
    vpc_id = aws_vpc.scoutflow_vpc.id
    cidr_block = "141.0.2.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        Name = "${var.project_name}_private_1" 
        "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_subnet" "private_2" {
    vpc_id = aws_vpc.scoutflow_vpc.id
    cidr_block = "141.0.3.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]

    tags = {
        Name = "${var.project_name}_private_2" 
        "kubernetes.io/role/internal-elb" = "1"
    }
}

#Elastic IP for NAT Gateway
resource "aws_eip" "nat_1" {
    domain = "vpc"

    tags = {
        Name = "${var.project_name}_nat_eip_1"
    }
}

resource "aws_eip" "nat_2" {
    domain = "vpc"

    tags = {
        Name = "${var.project_name}_nat_eip_2"
    }
}



# NAT Gateway - Placed in Public Subnets
resource "aws_nat_gateway" "gw_1" {
    allocation_id = aws_eip.nat_1.id
    subnet_id = aws_subnet.public_1.id

    tags = {
        Name = "${var.project_name}_nat_gw1"
    }

    depends_on = [aws_internet_gateway.scoutflow_igw]
}

resource "aws_nat_gateway" "gw_2" {
    allocation_id = aws_eip.nat_2.id
    subnet_id = aws_subnet.public_2.id

    tags = {
        Name = "${var.project_name}_nat_gw2"
    }

    depends_on = [aws_internet_gateway.scoutflow_igw]
}

# Public Route Tables (Traffic -> IGW)
resource "aws_route_table" "public_1" {
    vpc_id = aws_vpc.scoutflow_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.scoutflow_igw.id
    }

    tags = {
        Name = "${var.project_name}_public_rt"
    }
}

# Private Route Tables (Traffic -> NAT)
resource "aws_route_table" "private_1" {
    vpc_id = aws_vpc.scoutflow_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.gw_1.id
    }

    tags = {
        Name = "${var.project_name}_private_rt_1"
    }
}

resource "aws_route_table" "private_2" {
    vpc_id = aws_vpc.scoutflow_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.gw_2.id
    }

    tags = {
        Name = "${var.project_name}_private_rt_2"
    }
}

# Route Tables Association
resource "aws_route_table_association" "public_1" {
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.public_1.id
}

resource "aws_route_table_association" "public_2" {
    subnet_id = aws_subnet.public_2.id
    route_table_id = aws_route_table.public_1.id
}

resource "aws_route_table_association" "private_1" {
    subnet_id = aws_subnet.private_1.id
    route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
    subnet_id = aws_subnet.private_2.id
    route_table_id = aws_route_table.private_2.id
}
