# AWS Validator Security Group
resource "aws_security_group" "validator" {
  name        = "validator-sg"
  description = "Security group for Solana validator"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "validator-sg"
  }
}

# GCP Validator Firewall Rules
resource "google_compute_firewall" "validator" {
  name          = "validator-rules"
  network       = google_compute_network.main.name
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22", "8888"]
  }

  # Solana ports - open to all
  allow {
    protocol = "tcp"
    ports    = ["8000-8020", "8899-9000"]
  }

  allow {
    protocol = "udp"
    ports    = ["8000-8020", "8899-9000"]
  }

  # VPN traffic
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  target_tags = ["validator"]
}

# GCP SSH Access Rule
resource "google_compute_firewall" "validator_ssh" {
  name          = "validator-ssh"
  network       = google_compute_network.main.name
  source_ranges = [var.admin_ip]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["validator"]
}

# Allow port 8888 access from admin IP
resource "aws_security_group_rule" "validator_admin" {
  type              = "ingress"
  from_port         = 8888
  to_port           = 8888
  protocol          = "tcp"
  cidr_blocks       = [var.admin_ip]
  security_group_id = aws_security_group.validator.id
}

# SSH access from admin IP only
resource "aws_security_group_rule" "validator_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.admin_ip, var.aws_vpc_cidr]
  security_group_id = aws_security_group.validator.id
}

# Salt minion ports
resource "aws_security_group_rule" "validator_salt" {
  type                     = "ingress"
  from_port                = 4505
  to_port                  = 4506
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.salt_master.id
  security_group_id        = aws_security_group.validator.id
}