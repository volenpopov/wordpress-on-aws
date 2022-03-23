variable "region" {
  description = "The AWS region in which the infrastructure will be deployed."
  type        = string
}

variable "vpc_cidr" {
  description = "The VPC CIDR. It defines the range of available IP addresses within our custom network."
  type        = string
  default     = "10.16.0.0/21"
}

variable "all_ipv4_cidr" {
  description = "A route table's destination default CIDR matching all IPv4 addresses."
  type        = string
  default     = "0.0.0.0/0"
}

variable "project_tiers" {
  description = "The various tiers required for the project's implementation."
  type        = map(string)
  default = {
    compute  = "compute"
    storage  = "storage"
    database = "database"
  }
}

variable "db_subnet_group_name" {
  description = "The name of the database subnet group."
  type        = string
  default     = "sn-db-grp"
}

variable "port_mappings" {
  description = "Mapping of used protocols and their respective port."
  type        = map(string)
  default = {
    http  = "80"
    mysql = "3306"
    nfs   = "2049"
  }
}

variable "subnet_prefix" {
  description = "A prefix used in the names of all subnets."
  type        = string
  default     = "sn"
}