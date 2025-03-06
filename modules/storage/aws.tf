resource "aws_s3_bucket" "validator" {
  bucket = "aws-sol-val"
}

resource "aws_s3_bucket_lifecycle_configuration" "validator" {
  bucket = aws_s3_bucket.validator.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    noncurrent_version_transition {
      noncurrent_days = 7
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  rule {
    id     = "abort_incomplete_multipart_uploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
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