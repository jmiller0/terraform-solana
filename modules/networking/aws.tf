resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "solana-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "solana-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "solana-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "solana-rt"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Base security group with static rules
resource "aws_security_group" "salt_master" {
  name        = "salt-master-sg"
  description = "Security group for Salt master"
  vpc_id      = aws_vpc.main.id

  # SSH access from admin IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
    description = "SSH access from admin IP"
  }

  # Salt master ports (4505-4506) for VPC CIDR and admin IP
  ingress {
    from_port   = 4505
    to_port     = 4506
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr, var.gcp_vpc_cidr, var.admin_ip]
    description = "Salt master ports for VPC and admin"
  }

  # Vault ports (8200)
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr, var.gcp_vpc_cidr, var.admin_ip]
    description = "Vault access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "salt-master-sg"
  }

  lifecycle {
    # Ignore changes to ingress since we manage instance IPs separately
    ignore_changes = [ingress]
  }
}

# Separate rule for GCP validator public IP
resource "aws_security_group_rule" "salt_master_gcp_validator" {
  count             = var.gcp_validator_external_ips != null ? length(var.gcp_validator_external_ips) : 0
  type              = "ingress"
  from_port         = 4505
  to_port           = 4506
  protocol          = "tcp"
  cidr_blocks       = ["${var.gcp_validator_external_ips[count.index]}/32"]
  security_group_id = aws_security_group.salt_master.id
  description       = "Allow Salt minion ports from GCP validator public IP"
}

