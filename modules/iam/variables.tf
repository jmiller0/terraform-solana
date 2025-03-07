variable "github_username" {
  description = "GitHub username"
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

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for validator DNS updates"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID for service account creation"
  type        = string
} 