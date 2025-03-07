# Test AWS Minion Instance
resource "aws_instance" "test_minion" {
  count         = var.create_aws_instances && var.create_test_minions ? 1 : 0
  depends_on    = [aws_instance.salt_master]
  ami           = local.ubuntu_ami[local.is_arm_instance ? "arm64" : "x86_64"]
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [var.aws_security_group_id]
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.validator.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/templates/salt-minion-init.tpl", {
    master        = "salt-master.${var.aws_root_zone}"
    minion_id     = "aws-test-minion"
    aws_root_zone = "${var.aws_root_zone}"
  })

  tags = {
    Name = "aws-test-minion"
    Role = "test-minion"
  }

  lifecycle {
    ignore_changes = [
      ami, user_data, private_dns_name_options
    ]
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "resource-name"
  }

  # Create required directories
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/salt/minion.d"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Add file provisioner to copy Vault configuration
  provisioner "file" {
    source      = "${path.root}/srv/salt/common/files/vault.conf"
    destination = "/tmp/vault.conf"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Add file provisioner to copy grains configuration
  provisioner "file" {
    content     = "aws_root_zone: ${var.aws_root_zone}\n"
    destination = "/tmp/grains"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Move files to final locations and set permissions
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/vault.conf /etc/salt/minion.d/",
      "sudo mv /tmp/grains /etc/salt/grains",
      "sudo chown root:root /etc/salt/minion.d/vault.conf /etc/salt/grains",
      "sudo chmod 644 /etc/salt/minion.d/vault.conf /etc/salt/grains"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

# Test GCP Minion Instance
resource "google_compute_instance" "test_minion" {
  count        = var.create_gcp_instances && var.create_test_minions ? 1 : 0
  depends_on   = [aws_instance.salt_master]
  name         = "gcp-test-minion"
  hostname     = "gcp-test-minion.${var.aws_root_zone}"
  machine_type = "e2-standard-2" # Smallest instance for testing
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard" # Cheaper disk for testing
    }
  }

  network_interface {
    network    = var.gcp_network_name
    subnetwork = var.gcp_subnetwork_name
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
    role     = "test-minion"
    hostname = "gcp-test-minion"
  }

  metadata_startup_script = templatefile("${path.module}/templates/salt-minion-init.tpl", {
    master        = "salt-master.${var.aws_root_zone}"
    minion_id     = "gcp-test-minion"
    aws_root_zone = "${var.aws_root_zone}"
  })

  # Configure spot instance
  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  tags = ["test-minion", "salt-minion"]
  lifecycle {
    ignore_changes = [
      hostname, metadata_startup_script, metadata
    ]
  }
}

# Add AWS test minion IP to Salt master security group
resource "aws_security_group_rule" "salt_master_aws_test_minion" {
  count = var.create_aws_instances && var.create_test_minions ? 1 : 0

  type              = "ingress"
  from_port         = 4505
  to_port           = 4506
  protocol          = "tcp"
  security_group_id = var.aws_salt_master_sg_id
  cidr_blocks       = ["${aws_instance.test_minion[count.index].public_ip}/32"]

  description = "Allow Salt minion ports from AWS test minion"
}

# Add GCP test minion IP to Salt master security group
resource "aws_security_group_rule" "salt_master_gcp_test_minion" {
  count = var.create_gcp_instances && var.create_test_minions ? 1 : 0

  type              = "ingress"
  from_port         = 4505
  to_port           = 4506
  protocol          = "tcp"
  security_group_id = var.aws_salt_master_sg_id
  cidr_blocks       = ["${google_compute_instance.test_minion[count.index].network_interface[0].access_config[0].nat_ip}/32"]

  description = "Allow Salt minion ports from GCP test minion"
}

# Add Vault access rule for GCP test minion to Salt master
resource "aws_security_group_rule" "salt_master_gcp_test_minion_vault" {
  count             = var.create_gcp_instances && var.create_test_minions ? 1 : 0
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  security_group_id = var.aws_salt_master_sg_id
  cidr_blocks       = ["${google_compute_instance.test_minion[count.index].network_interface[0].access_config[0].nat_ip}/32"]

  description = "Allow Vault access from GCP test minion"
}

# Add Vault access rule for AWS test minion to Salt master
resource "aws_security_group_rule" "salt_master_aws_test_minion_vault" {
  count             = var.create_aws_instances && var.create_test_minions ? 1 : 0
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  security_group_id = var.aws_salt_master_sg_id
  cidr_blocks       = ["${aws_instance.test_minion[count.index].public_ip}/32"]

  description = "Allow Vault access from AWS test minion"
} 