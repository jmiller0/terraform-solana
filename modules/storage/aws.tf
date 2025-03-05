resource "aws_s3_bucket" "validator" {
  bucket = "aws-sol-val"
}

resource "aws_s3_bucket_public_access_block" "validator" {
  bucket = aws_s3_bucket.validator.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "validator" {
  bucket = aws_s3_bucket.validator.id
  depends_on = [aws_s3_bucket_public_access_block.validator]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowValidatorInstance"
        Effect    = "Allow"
        Principal = {
          AWS = var.validator_instance_role
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.validator.arn}",
          "${aws_s3_bucket.validator.arn}/*"
        ]
      },
      {
        Sid       = "AllowVPCAndAdminAccess"
        Effect    = "Allow"
        Principal = {"AWS": "*"}
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.validator.arn}",
          "${aws_s3_bucket.validator.arn}/*"
        ]
        Condition = {
          IpAddress = {
            "aws:SourceIp": [
              var.admin_ip,
              var.aws_vpc_cidr,
              var.gcp_vpc_cidr
            ]
          }
        }
      },
      {
        Sid       = "AllowCenterDomain"
        Effect    = "Allow"
        Principal = {"AWS": "*"}
        Action    = ["s3:*"]
        Resource  = [
          "${aws_s3_bucket.validator.arn}",
          "${aws_s3_bucket.validator.arn}/*"
        ]
        Condition = {
          StringLike = {
            "aws:SourceHost": ["*.${var.aws_root_zone}"]
          }
        }
      },
      {
        Sid       = "AllowSaltMasterAccess"
        Effect    = "Allow"
        Principal = {
          AWS = var.salt_master_instance_role
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.validator.arn}",
          "${aws_s3_bucket.validator.arn}/*"
        ]
      }
    ]
  })
} 