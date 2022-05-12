variable "ec2_wordpress_role_name" {
    description = "The name of the instance profile and IAM role containing all the required permissions for our wordpress application instances."
    type = string
    default = "EC2Wordpress"
}