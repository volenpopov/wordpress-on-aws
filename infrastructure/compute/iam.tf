resource "aws_iam_role" "this" {
  name = var.ec2_wordpress_role_name

  assume_role_policy = file("${path.module}/policies/ec2-role-trust-policy.json")
}

resource "aws_iam_instance_profile" "this" {
  name = var.ec2_wordpress_role_name
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.ssm.arn
}

resource "aws_iam_role_policy_attachment" "cwagent" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.cwagent.arn
}

data "aws_iam_policy" "ssm" {
  name = "AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "cwagent" {
  name = "CloudWatchAgentServerPolicy"
}