locals {
  azs = ["${var.region}a", "${var.region}b", "${var.region}c"]

  compute_subnets_range  = range(0, 3)
  storage_subnets_range  = range(3, 6)
  database_subnets_range = range(6, 8)
  public_subnets_range   = range(8, 11)

  public_subnets = [for index in local.public_subnets_range : cidrsubnet(var.vpc_cidr, 4, index)]

  private_subnets_config = merge(
    {
      for index in local.compute_subnets_range : index => {
        cidr = cidrsubnet(var.vpc_cidr, 4, index)
        tier = var.project_tiers.compute
        az   = element(local.azs, index)
      }
    },
    {
      for index in local.storage_subnets_range : index => {
        cidr = cidrsubnet(var.vpc_cidr, 4, index)
        tier = var.project_tiers.storage
        az   = element(local.azs, index)
      }
    },
    {
      for index in local.database_subnets_range : index => {
        cidr = cidrsubnet(var.vpc_cidr, 4, index)
        tier = var.project_tiers.database
        az   = element(local.azs, index)
      }
    },
  )
}