variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
}

variable "gcp_vpc_cidr" {
  description = "CIDR block for GCP VPC"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "admin_ip" {
  description = "Admin IP address for SSH access"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for all resources"
  type        = string
}

variable "gcp_validator_external_ips" {
  type        = list(string)
  description = "External IPs of GCP validators"
  default     = []
}

variable "aws_region" {
  description = "AWS region for networking resources"
  type        = string
} 