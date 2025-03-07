# Create IAM role for salt-master
resource "aws_iam_role" "salt_master" {
  name = "salt-master-role"

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

# Add EC2 permissions to Salt master role
resource "aws_iam_role_policy" "salt_master_ec2_policy" {
  name = "salt-master-ec2-policy"
  role = aws_iam_role.salt_master.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create instance profile for Salt master
resource "aws_iam_instance_profile" "salt_master" {
  name = "salt-master-profile"
  role = aws_iam_role.salt_master.name
} 