# AWS Configuration
variable "aws_root_zone" {
  description = "AWS Route53 root zone"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "subnet_id" {
  description = "AWS subnet ID"
  type        = string
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type        = string
}

variable "aws_security_group_id" {
  description = "AWS security group ID"
  type        = string
}

variable "aws_salt_master_sg_id" {
  description = "AWS security group ID for Salt master"
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
}

variable "gcp_zone" {
  description = "GCP zone for instances"
  type        = string
}

variable "gcp_network_name" {
  description = "GCP network name"
  type        = string
}

variable "gcp_subnetwork_name" {
  description = "GCP subnetwork name"
  type        = string
}

variable "gcp_vpc_cidr" {
  description = "CIDR block for GCP VPC"
  type        = string
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
  description = "Whether to create the GCP instances"
  type        = bool
  default     = false
}

variable "create_aws_instances" {
  description = "Whether to create the AWS instances"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "instance_type" {
  description = "EC2 instance type for the salt master"
  type        = string
  default     = "t4g.medium"
}

# IAM Configuration
variable "validator_instance_profile_name" {
  description = "Name of the instance profile for validator instances"
  type        = string
}

variable "salt_master_instance_profile_name" {
  description = "Name of the instance profile for salt master instance"
  type        = string
}

variable "validator_service_account_email" {
  description = "Email of the GCP service account for validator instances"
  type        = string
}


