data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = var.networking_remote_state_key
    region = var.region
  }
}

resource "aws_db_instance" "this" {
  engine         = "mysql"
  engine_version = "5.7.31"
  instance_class = "db.t3.micro"
  identifier = "wordpress-db"

  db_name              = var.db_name
  username             = var.db_user
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"

  allocated_storage     = 10
  max_allocated_storage = 50

  multi_az               = true
  db_subnet_group_name   = data.terraform_remote_state.networking.outputs.db_subnet_group_name
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.db_security_group_id]

  deletion_protection     = true
  backup_retention_period = 7

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  # skip_final_snapshot = true
}

resource "aws_ssm_parameter" "db_name" {
  name  = "${var.ssm_db_params_prefix}/name"
  type  = "String"
  value = var.db_name
}

resource "aws_ssm_parameter" "db_user" {
  name  = "${var.ssm_db_params_prefix}/user"
  type  = "String"
  value = var.db_user
}

resource "aws_ssm_parameter" "db_password" {
  name  = "${var.ssm_db_params_prefix}/password"
  type  = "SecureString"
  value = var.db_password
}