resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  enable_dns_hostnames   = true

  tags = {
    Name = "${local.cluster_name}-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  count = var.subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "${local.cluster_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count = var.subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + var.subnet_count)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "${local.cluster_name}-private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.cluster_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.cluster_name}-public-route-table"
  }
}

resource "aws_route_table_association" "public_subnets" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "this" {
  count                   = 1
  allocation_id           = aws_eip.nat_eip.id
  subnet_id               = aws_subnet.public_subnets[0].id
  connectivity_type       = "public"

  tags = {
    Name = "${local.cluster_name}-nat-gateway"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name = "${local.cluster_name}-nat-eip"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = {
    Name = "${local.cluster_name}-private-route-table"
  }
}

resource "aws_route_table_association" "private_subnets" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}
