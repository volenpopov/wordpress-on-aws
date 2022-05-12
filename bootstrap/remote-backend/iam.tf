resource "aws_iam_role" "replication" {
  name = "TFS3Replication"

  assume_role_policy = file("${path.module}/policies/s3-replication-assume-policy.json")
}

resource "aws_iam_policy" "replication" {
  name = "TFS3ReplicationPolicy"

  policy = templatefile("${path.module}/policies/s3-replication-policy.json", {
    account_id             = data.aws_caller_identity.this.account_id
    source_bucket_arn      = aws_s3_bucket.source.arn
    destination_bucket_arn = aws_s3_bucket.destination.arn
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

data "aws_caller_identity" "this" {}
