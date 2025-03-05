# AWS IAM Role for Validator
resource "aws_iam_role" "validator" {
  name = "validator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# S3 Access Policy for Validator
resource "aws_iam_role_policy" "validator_s3" {
  name = "validator-s3-policy"
  role = aws_iam_role.validator.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:PutObjectTagging",
          "s3:GetObjectTagging",
          "s3:GetBucketTagging",
          "s3:HeadBucket",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetObjectAcl",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::aws-sol-val",
          "arn:aws:s3:::aws-sol-val/*"
        ]
      }
    ]
  })
}

# EC2 Access Policy for Validator
resource "aws_iam_role_policy" "validator_ec2" {
  name = "validator-ec2-policy"
  role = aws_iam_role.validator.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:GetConsoleOutput",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAddresses",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DescribeParameters",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Add Route53 permissions to instance role
resource "aws_iam_role_policy" "route53_policy" {
  name = "route53-update-policy"
  role = aws_iam_role.validator.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = ["arn:aws:route53:::hostedzone/${var.hosted_zone_id}"]
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "validator" {
  name = "validator-profile"
  role = aws_iam_role.validator.name
} 