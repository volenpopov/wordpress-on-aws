# VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# INTERNET_GATEWAY
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# ROUTE_TABLES
resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route {
    cidr_block = var.all_ipv4_cidr
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "rt-main"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "rt-private"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(keys(local.private_subnets_config))
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# PUBLIC SUBNETS
resource "aws_subnet" "public" {
  count = length(local.public_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.public_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "sn-public-${substr(local.azs[count.index], -1, 1)}"
  }
}

# PRIVATE SUBNETS
resource "aws_subnet" "private" {
  count = length(keys(local.private_subnets_config))

  vpc_id            = aws_vpc.this.id
  cidr_block        = lookup(local.private_subnets_config, count.index, null).cidr
  availability_zone = lookup(local.private_subnets_config, count.index, null).az

  tags = {
    Name = "sn-${lookup(local.private_subnets_config, count.index, null).tier}-${substr(lookup(local.private_subnets_config, count.index, null).az, -1, 1)}"
  }
}
