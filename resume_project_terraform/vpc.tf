data "aws_availability_zones" "available" {
    state = "available"
}

resource "aws_vpc" "status-vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    

    tags = {
      Name = "StatusVPC"
    }
}

resource "aws_internet_gateway" "status-igw" {
    vpc_id = aws_vpc.status-vpc.id

    tags = {
      Name = "StatusIGW"
    }
}

resource "aws_subnet" "status-public_subnets" {
    count = length(var.public_subnet_cidrs)

    vpc_id = aws_vpc.status-vpc.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true

    tags = {
      Name = "Status-PublicSN"
    } 
}


resource "aws_subnet" "status-private_subnets" {
    count = length(var.private_subnet_cidrs)

    vpc_id = aws_vpc.status-vpc.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
      Name = "Status-PrivateSN"
    } 
}

resource "aws_route_table" "status-rt" {
    vpc_id = aws_vpc.status-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.status-igw.id
        
    }    
    tags = {
      Name = "Status-RT"
    }   
}

resource "aws_route_table_association" "status-rta" {
    count = length(aws_subnet.status-public_subnets)

    subnet_id = aws_subnet.status-public_subnets[count.index].id
    route_table_id = aws_route_table.status-rt.id
  
}


resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
      Name = "Status-NAT_EIP"
    }
}

resource "aws_nat_gateway" "status-nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.status-public_subnets[0].id
  
  
  depends_on = [ aws_internet_gateway.status-igw ]
}


resource "aws_route_table" "status_private_rt" {
  vpc_id = aws_vpc.status-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.status-nat.id
  }

  tags = {
      Name = "Status-Private-RT"
    }

}


resource "aws_route_table_association" "status-private-rta" {
    count = length(aws_subnet.status-private_subnets)

    subnet_id = aws_subnet.status-private_subnets[count.index].id
    route_table_id = aws_route_table.status_private_rt.id
  
}

