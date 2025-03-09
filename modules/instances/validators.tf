# AWS Validator Instance
resource "aws_instance" "validator" {
  count         = var.create_aws_instances && var.create_validators ? 1 : 0
  depends_on    = [aws_instance.salt_master]
  ami           = local.ubuntu_ami[local.is_arm_instance ? "arm64" : "x86_64"]
  instance_type = "c6a.large"
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [var.aws_security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  iam_instance_profile = var.validator_instance_profile_name

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price                      = "1.00"
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  user_data = templatefile("${path.module}/templates/salt-minion-init.tpl", {
    master        = "salt-master.${var.aws_root_zone}"
    minion_id     = "solana-validator-aws-${count.index}"
    aws_root_zone = "${var.aws_root_zone}"
  })

  root_block_device {
    volume_size           = 100 # GB
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "solana-validator-aws-${count.index}"
    Environment = "testnet"
    Role        = "validator"
    SaltMinion  = "true"
    Terraform   = "true"
    Project     = "solana"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# GCP Validator Instance
resource "google_compute_instance" "validator" {
  count        = var.create_gcp_instances && var.create_validators ? 1 : 0
  depends_on   = [aws_instance.salt_master]
  name         = "solana-validator-gcp-${count.index}"
  machine_type = "c3d-highcpu-60"
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 100
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source = google_compute_disk.validator_data[count.index].id
  }

  network_interface {
    network    = var.gcp_network_name
    subnetwork = var.gcp_subnetwork_name
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys    = "ubuntu:${var.ssh_public_key}"
    environment = "testnet"
    role        = "validator"
    salt-minion = "true"
    terraform   = "true"
    project     = "solana"
  }

  metadata_startup_script = templatefile("${path.module}/templates/salt-minion-init.tpl", {
    master        = "salt-master.${var.aws_root_zone}"
    minion_id     = "solana-validator-gcp-${count.index}"
    aws_root_zone = "${var.aws_root_zone}"
  })

  service_account {
    email  = var.validator_service_account_email
    scopes = ["storage-rw"]
  }

  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  tags = ["validator", "salt-minion", "solana", "testnet", "terraform", "validator-${count.index}"]
}

# GCP Data Disk
resource "google_compute_disk" "validator_data" {
  count = var.create_gcp_instances && var.create_validators ? 1 : 0
  name  = "solana-validator-gcp-${count.index}-data"
  type  = "pd-ssd"
  zone  = var.gcp_zone
  size  = 400

  physical_block_size_bytes = 4096

  labels = {
    environment = "testnet"
    role        = "validator"
    project     = "solana"
    terraform   = "true"
  }
}

# Manage EBS volume separately
resource "aws_ebs_volume" "validator_data" {
  count             = var.create_aws_instances && var.create_validators ? 1 : 0
  availability_zone = aws_instance.validator[count.index].availability_zone
  size              = 1024
  type              = "gp3"
  iops              = 16000
  throughput        = 1000

  tags = {
    Name        = "solana-validator-aws-${count.index}-data"
    Environment = "testnet"
    Role        = "validator"
    Project     = "solana"
    Terraform   = "true"
  }
}

# Attach the volume
resource "aws_volume_attachment" "validator_data" {
  count                          = var.create_aws_instances && var.create_validators ? 1 : 0
  device_name                    = "/dev/xvdf"
  volume_id                      = aws_ebs_volume.validator_data[count.index].id
  instance_id                    = aws_instance.validator[count.index].id
  force_detach                   = false
  stop_instance_before_detaching = false
}

# Add GCP validator IP to Salt master security group
resource "aws_security_group_rule" "salt_master_gcp_validator" {
  count = var.create_gcp_instances && var.create_validators ? 1 : 0

  type              = "ingress"
  from_port         = 4505
  to_port           = 4506
  protocol          = "tcp"
  security_group_id = var.aws_salt_master_sg_id
  cidr_blocks       = ["${google_compute_instance.validator[count.index].network_interface[0].access_config[0].nat_ip}/32"]
  description       = "Allow Salt minion ports from GCP validator ${count.index}"

  lifecycle {
    create_before_destroy = true
  }
}

# Add Vault access rule for GCP validator to Salt master
resource "aws_security_group_rule" "salt_master_gcp_validator_vault" {
  count = var.create_gcp_instances && var.create_validators ? 1 : 0

  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  security_group_id = var.aws_salt_master_sg_id
  cidr_blocks       = ["${google_compute_instance.validator[count.index].network_interface[0].access_config[0].nat_ip}/32"]
  description       = "Allow Vault access from GCP validator ${count.index}"

  lifecycle {
    create_before_destroy = true
  }
}

