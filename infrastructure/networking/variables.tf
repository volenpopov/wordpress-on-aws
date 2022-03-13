variable "region" {
  description = "The AWS region in which the infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "default_tags" {
  description = "The default tags that are applied to all resources. Configured on a provider level."
  type        = map(string)
  default = {
    App     = "wordpress"
    Creator = "terraform"
  }
}

variable "vpc_name" {
  description = "The name of the custom VPC that will hold all the required infrastructure for our Wordpress application."
  type        = string
  default     = "wordpress-vpc"
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
  type = map(string)
  default = {
    compute = "compute"
    storage = "storage"
    database = "database"
  }
}