variable "mfa_serial" {
  description = "The MFA serial number for your account's root user."
  type        = string
}

variable "mfa_code" {
  description = "The value displayed on your authentication device for your account's root user MFA."
  type        = string
}

/*
All of the values for the below variables NEED TO BE THE SAME as the ones specified in the backend.hcl file.
If you want to deploy to another region or use a different name for the DynamoDB table you need to edit the values for the variables in this file and in the backend.hcl file.
*/

variable "region" {
  description = "The AWS region in which the infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "backup_region" {
  description = "The backup AWS region used for increasing global resilience."
  type        = string
  default     = "eu-west-1"
}

variable "bucket" {
  description = "The name of the S3 source bucket that will serve as a remote terraform backend, storing all the terraform state files related to our infrastructure."
  type        = string
}

variable "dynamodb_table" {
  description = "The name of the DynamoDB table, which will be used as a locking mechanism for the our Terraform remote backend."
  type        = string
  default     = "terraform-state-lock"
}