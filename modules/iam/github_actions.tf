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
            # Match personal repository
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# Comprehensive permissions policy for all Terraform resources
resource "aws_iam_role_policy" "github_actions_test" {
  name = "github-actions-test-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EC2 Instance Management
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeTags",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeInstanceAttribute",
          
          # Spot Instance Management
          "ec2:RequestSpotInstances",
          "ec2:CancelSpotInstanceRequests",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:CreateSpotDatafeedSubscription",
          "ec2:DeleteSpotDatafeedSubscription",
          
          # VPC and Networking
          "ec2:DescribeVpcs",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:DescribeSubnets",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
          
          # Internet Gateway
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DescribeInternetGateways",
          
          # Route Tables
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:ReplaceRouteTableAssociation",
          "ec2:DescribeRouteTables",
          
          # EBS Volumes
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          
          # Key Pairs
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:ImportKeyPair",
          "ec2:DescribeKeyPairs",
          
          # IAM Management
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfilesForRole",
          
          # S3 Access
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:PutBucketVersioning",
          "s3:GetBucketVersioning",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock",
          
          # Route53 DNS Management
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:GetChange",
          
          # KMS for encryption
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          
          # CloudWatch Logs
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:DeleteLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
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