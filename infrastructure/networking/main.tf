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
  name        = "alb"
  description = "Allow IPv4 HTTP ALL IN and OUT only to EC2"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "alb_ingress_allow_http" {
  type              = "ingress"
  from_port         = var.port_mappings.http
  to_port           = var.port_mappings.http
  protocol          = "tcp"
  cidr_blocks       = [var.all_ipv4_cidr]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_allow_http" {
  type                     = "egress"
  from_port                = var.port_mappings.http
  to_port                  = var.port_mappings.http
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group" "ec2" {
  name        = "ec2"
  description = "Allow IPv4 HTTP IN from ALB and ALL OUTBOUND traffic"
  vpc_id      = aws_vpc.this.id
}

# resource "aws_security_group_rule" "ec2_ingress_allow_http_from_alb" {
#   type                     = "ingress"
#   from_port                = var.port_mappings.http
#   to_port                  = var.port_mappings.http
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ec2.id
#   source_security_group_id = aws_security_group.alb.id
# }

# resource "aws_security_group_rule" "ec2_ingress_allow_https_from_vpc_endpoint" {
#   type                     = "ingress"
#   from_port                = var.port_mappings.https
#   to_port                  = var.port_mappings.https
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ec2.id
#   source_security_group_id = aws_security_group.vpc_endpoint.id
# }

# resource "aws_security_group_rule" "ec2_ingress_allow_ssh" {
#   type              = "ingress"
#   from_port         = var.port_mappings.ssh
#   to_port           = var.port_mappings.ssh
#   protocol          = "tcp"
#   cidr_blocks       = [var.all_ipv4_cidr]
#   security_group_id = aws_security_group.ec2.id
# }

# TEST
resource "aws_security_group_rule" "ec2_ingress_allow_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.all_ipv4_cidr]
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "ec2_egress_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.all_ipv4_cidr]
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group" "efs" {
  name        = "efs"
  description = "Allow IPv4 NFS/EFS IN from EC2"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "efs_ingress_allow_nfs" {
  type                     = "ingress"
  from_port                = var.port_mappings.nfs
  to_port                  = var.port_mappings.nfs
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group" "rds" {
  name        = "mysql"
  description = "Allow IPv4 MySQL IN"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "mysql_ingress_allow_mysql" {
  type                     = "ingress"
  from_port                = var.port_mappings.mysql
  to_port                  = var.port_mappings.mysql
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group" "vpc_endpoint" {
  name        = "vpc_endpoint"
  description = "Allow IPv4 HTTPS IN from EC2 and ALL OUTBOUND traffic"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "vpc_endpoint_ingress_allow_https" {
  type                     = "ingress"
  from_port                = var.port_mappings.https
  to_port                  = var.port_mappings.https
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoint.id
  source_security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "vpc_endpoint_egress_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.all_ipv4_cidr]
  security_group_id = aws_security_group.vpc_endpoint.id
}

# ##################################
# # VPC Endpoints
# ##################################
# resource "aws_vpc_endpoint" "endpoint" {
#   count = length(var.vpc_endpoint_services)

#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.${var.region}.${var.vpc_endpoint_services[count.index]}"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [aws_security_group.vpc_endpoint.id]
#   subnet_ids         = matchkeys(aws_subnet.private.*.id, keys(local.private_subnets_config), local.compute_subnets_range)
#   # policy             = file("${path.module}/policies/${var.vpc_endpoint_services[count.index]}-endpoint-policy.json")

#   private_dns_enabled = true

#   tags = {
#     Name = "${var.vpc_endpoint_services[count.index]}-endpoint"
#   }
# }
