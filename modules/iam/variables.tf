variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "aws_region" {
  description = "AWS region for IAM role condition"
  type        = string
  default     = "us-east-1"
} 