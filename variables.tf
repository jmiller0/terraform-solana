# Network Configuration
variable "admin_ip" {
  description = "Admin IP address for SSH access"
  type        = string
  default     = "69.8.87.143/32"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gcp_vpc_cidr" {
  description = "CIDR block for GCP VPC"
  type        = string
  default     = "172.16.0.0/16"
}

# AWS Configuration
variable "aws_root_zone" {
  description = "AWS Route53 root zone"
  type        = string
}

variable "aws_zone_id" {
  description = "AWS Route53 hosted zone ID"
  type        = string
}

# GCP Configuration
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for all resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone for instances"
  type        = string
  default     = "us-central1-a"
}

# Instance Creation Flags
variable "create_validators" {
  description = "Whether to create the expensive validator instances"
  type        = bool
  default     = false
}

variable "create_test_minions" {
  description = "Whether to create small test minion instances"
  type        = bool
  default     = false
}

variable "create_gcp_instances" {
  description = "Whether to create GCP instances"
  type        = bool
  default     = false
}

variable "create_aws_instances" {
  description = "Whether to create AWS instances"
  type        = bool
  default     = false
}

# Authentication
variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}


