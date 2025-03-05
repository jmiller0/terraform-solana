# Use a specific Ubuntu 22.04 AMI
locals {
  ubuntu_ami = {
    # Ubuntu 22.04 LTS AMIs as of Jan 2024
    us-east-1 = "ami-0e1bed4f06a3b463d"  # N. Virginia
  }
}

# Get current AWS region
data "aws_region" "current" {}

# AWS Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key
} 