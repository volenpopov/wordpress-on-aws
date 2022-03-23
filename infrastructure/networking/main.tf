resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "wordpress-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

##################################
# Route Tables
##################################
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
  count = length(keys(local.private_subnets_config))

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

##################################
# Subnets
##################################
resource "aws_subnet" "public" {
  count = length(local.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnet_prefix}-public-${substr(local.azs[count.index], -1, 1)}"
  }
}

resource "aws_subnet" "private" {
  count = length(keys(local.private_subnets_config))

  vpc_id            = aws_vpc.this.id
  cidr_block        = lookup(local.private_subnets_config, count.index, null).cidr
  availability_zone = lookup(local.private_subnets_config, count.index, null).az

  tags = {
    Name = "${var.subnet_prefix}-${lookup(local.private_subnets_config, count.index, null).tier}-${substr(lookup(local.private_subnets_config, count.index, null).az, -1, 1)}"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = var.db_subnet_group_name
  subnet_ids = matchkeys(aws_subnet.private.*.id, keys(local.private_subnets_config), local.database_subnets_range)
}

##################################
# Security Groups
##################################
resource "aws_security_group" "alb" {
  name        = "alb_allow_http_in"
  description = "Allow HTTP IPv4 IN and OUT only to EC2"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = var.port_mappings.http
  to_port           = var.port_mappings.http
  protocol          = "tcp"
  cidr_blocks       = [var.all_ipv4_cidr]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "egress_http" {
  type                     = "egress"
  from_port                = var.port_mappings.http
  to_port                  = var.port_mappings.http
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group" "ec2" {
  name        = "ec2_allow_alb_in"
  description = "Allow HTTP IPv4 IN"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "ingress_alb" {
  type                     = "ingress"
  from_port                = var.port_mappings.http
  to_port                  = var.port_mappings.http
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "efs" {
  name        = "efs_allow_ec2_in"
  description = "Allow NFS/EFS IPv4 IN"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "ingress_nfs" {
  type                     = "ingress"
  from_port                = var.port_mappings.nfs
  to_port                  = var.port_mappings.nfs
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group" "rds" {
  name        = "mysql_allow_ec2_in"
  description = "Allow MySQL IN"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "ingress_mysql" {
  type                     = "ingress"
  from_port                = var.port_mappings.mysql
  to_port                  = var.port_mappings.mysql
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.ec2.id
}

##################################
# VPC Endpoints
##################################
resource "aws_vpc_endpoint" "cwlogs" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.ec2.id]

  subnet_ids = matchkeys(aws_subnet.private.*.id, keys(local.private_subnets_config), local.compute_subnets_range)

  policy = jsonencode({
    "Statement" : [
      {
        "Sid" : "PutOnly",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })

  private_dns_enabled = true

  tags = {
    Name = "cwlogs-endpoint"
  }
}

# TODO: Add more VPC endpoints - SSM, etc.