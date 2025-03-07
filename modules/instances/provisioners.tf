# Common Salt minion provisioning
resource "null_resource" "salt_minion_provisioner" {
  # Create one provisioner for each instance that needs Salt setup
  for_each = {
    for instance in concat(
      var.create_aws_instances && var.create_test_minions ? [{ name = "aws-test-minion", ip = aws_instance.test_minion[0].public_ip }] : [],
      var.create_gcp_instances && var.create_test_minions ? [{ name = "gcp-test-minion", ip = google_compute_instance.test_minion[0].network_interface[0].access_config[0].nat_ip }] : [],
      var.create_aws_instances && var.create_validators ? [{ name = "aws-validator", ip = aws_instance.validator[0].public_ip }] : [],
      var.create_gcp_instances && var.create_validators ? [{ name = "gcp-validator", ip = google_compute_instance.validator[0].network_interface[0].access_config[0].nat_ip }] : []
    ) : instance.name => instance
  }

  triggers = {
    instance_ip = each.value.ip
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
      host        = each.value.ip
    }
  }

  # Copy Vault configuration
  provisioner "file" {
    source      = "${path.root}/srv/salt/common/files/vault.conf"
    destination = "/tmp/vault.conf"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = each.value.ip
    }
  }

  # Copy grains configuration
  provisioner "file" {
    content     = "aws_root_zone: ${var.aws_root_zone}\n"
    destination = "/tmp/grains"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = each.value.ip
    }
  }

  # Move files and set permissions
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
      host        = each.value.ip
    }
  }

  depends_on = [
    aws_instance.test_minion,
    google_compute_instance.test_minion,
    aws_instance.validator,
    google_compute_instance.validator
  ]
} 