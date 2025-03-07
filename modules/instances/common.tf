# Get current AWS region
data "aws_region" "current" {}

# Get latest Ubuntu 22.04 AMI for ARM64
data "aws_ami" "ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# Get latest Ubuntu 22.04 AMI for x86_64
data "aws_ami" "ubuntu_x86_64" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  # Map instance architecture to appropriate AMI
  ubuntu_ami = {
    arm64  = data.aws_ami.ubuntu_arm64.id
    x86_64 = data.aws_ami.ubuntu_x86_64.id
  }

  # Helper to determine architecture based on instance type prefix
  is_arm_instance = can(regex("^(t4g|c6g|c7g|r6g|x2g|a1)", var.instance_type))
}

# AWS Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key
} 