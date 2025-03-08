terraform {
  required_version = ">= 1.11.1"
  backend "s3" {
    bucket         = "terraform-state-solana-validator"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.24.0"
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