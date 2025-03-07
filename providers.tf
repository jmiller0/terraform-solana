terraform {
  required_version = ">= 1.10.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  common_labels = {
    environment = "dev"
    service     = "solana"
    project     = "validator"
    managed_by  = "terraform"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "Dev"
      Service     = "Solana"
      Project     = "Validator"
      ManagedBy   = "Terraform"
    }
  }
}

provider "google" {
  region  = var.gcp_region
  project = var.gcp_project_id
} 