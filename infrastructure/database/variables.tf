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

variable "remote_state_bucket_name" {
  description = "The bucket name of the S3 remote backend."
  type        = string
}

variable "networking_remote_state_key" {
  description = "The key for the networking state file inside of the remote state bucket."
  type        = string
}

variable "ssm_db_params_prefix" {
  description = "The prefix used for all parameters related to the database."
  type        = string
  default     = "/wordpress/db"
}

variable "db_name" {
  description = "The name of the database."
  type        = string

  validation {
    condition     = length(var.db_name) >= 3 && length(var.db_name) <= 15 && can(regex("^[a-zA-Z]+$", var.db_name))
    error_message = "The database name must be between 3 and 15 characters long."
  }
}

variable "db_user" {
  description = "The name of the database user that will be used for authenticating with the database."
  type        = string

  validation {
    condition     = length(var.db_user) >= 3 && length(var.db_user) <= 15
    error_message = "The database user must be between 3 and 15 characters long."
  }
}

variable "db_password" {
  description = "The database password used for authentication with the database."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 50
    error_message = "The database password must be between 8 and 50 characters long."
  }
}
