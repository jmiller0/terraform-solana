variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
}

variable "gcp_vpc_cidr" {
  description = "CIDR block for GCP VPC"
  type        = string
}

variable "admin_ip" {
  description = "Admin IP address for access"
  type        = string
}

variable "validator_instance_role" {
  description = "IAM role ARN for validator instance"
  type        = string
}

variable "validator_service_account" {
  description = "GCP service account email for validator"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for all resources"
  type        = string
}

variable "salt_master_instance_role" {
  description = "IAM role ARN for salt master instance"
  type        = string
}

variable "aws_root_zone" {
  description = "AWS Route53 root zone"
  type        = string
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    environment = "dev"
    service     = "solana"
    project     = "validator"
    managed_by  = "terraform"
  }
} 