# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1","1c58a3a8518e8759bf075b76b750d4f2df264fcd"] # GitHub Actions' thumbprint
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-test"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Adjust this to match your GitHub repository
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# Limited permissions policy for testing
resource "aws_iam_role_policy" "github_actions_test" {
  name = "github-actions-test-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EC2 permissions
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:DescribeTags",
          # VPC permissions
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          # IAM permissions
          "iam:GetRole",
          "iam:GetRolePolicy",
          # S3 permissions for Terraform state (if using S3 backend)
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          # Route53 permissions
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion": var.aws_region
          }
        }
      }
    ]
  })
} 