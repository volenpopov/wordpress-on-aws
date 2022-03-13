terraform {
  required_version = "~> 1.1.7"

  backend "s3" {
    key = "terraform-remote-backend/terraform.tfstate"
  }
}