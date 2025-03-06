# Create IAM role for salt-master
resource "aws_iam_role" "salt_master" {
  name = "salt-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Add EC2 permissions to Salt master role
resource "aws_iam_role_policy" "salt_master_ec2_policy" {
  name = "salt-master-ec2-policy"
  role = aws_iam_role.salt_master.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "salt_master" {
  name = "salt-master-profile"
  role = aws_iam_role.salt_master.name
}

resource "aws_instance" "salt_master" {
  ami           = local.ubuntu_ami[data.aws_region.current.name]
  instance_type = "t3a.medium"
  subnet_id     = var.subnet_id
  key_name      = aws_key_pair.deployer.key_name
  iam_instance_profile = aws_iam_instance_profile.salt_master.name

  vpc_security_group_ids = [var.aws_salt_master_sg_id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    tags = {
      Name        = "salt-master-root"
      Environment = "Dev"
      Service     = "Salt"
    }
  }

  user_data = data.cloudinit_config.salt_master.rendered

  tags = {
    Name        = "salt-master"
    Role        = "salt-master"
    Environment = "Dev"
    Service     = "Salt"
  }

  lifecycle {
    ignore_changes = [user_data]
  }

  # Add file provisioner to copy srv directory
  provisioner "file" {
    source      = "${path.root}/srv/salt"
    destination = "/tmp/salt"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Add remote-exec provisioner to move files and set permissions
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /srv",
      "sudo mv /tmp/salt /srv/",
      "sudo chown -R root:root /srv",
      "sudo chmod -R 755 /srv",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

# Allow Salt master to access its own Vault server (public IP)
resource "aws_security_group_rule" "salt_master_vault_self_public" {
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.salt_master.public_ip}/32"]
  security_group_id = var.aws_salt_master_sg_id
  description       = "Allow Salt master to access its own Vault server (public IP)"
}

output "private_ip" {
  value = aws_instance.salt_master.private_ip
}

output "public_ip" {
  value = aws_instance.salt_master.public_ip
}

output "instance_id" {
  value = aws_instance.salt_master.id
}

locals {
  # Read keypairs if they exist, otherwise use empty string
  validator_keypairs = {
    for key in ["authorized-withdrawer", "stake", "validator", "vote-account"] :
    key => fileexists("./validator-keys/${key}-keypair.json") ? file("./validator-keys/${key}-keypair.json") : ""
  }
}

data "cloudinit_config" "salt_master" {
  gzip          = false
  base64_encode = false

  # Part 1: Your existing salt-master-init.tpl
  part {
    filename     = "salt-master-init.tpl"
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/salt-master-init.tpl", {
      aws_root_zone = var.aws_root_zone
    })
  }

  # Part 2: Store keypairs in Vault (only if they exist)
  part {
    filename     = "store-keypairs.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
      #!/bin/bash
      export VAULT_SKIP_VERIFY=true
      export VAULT_ADDR="https://127.0.0.1:8200"
      export VAULT_TOKEN=$(cat /etc/salt/vault_token)
      
      # Only process keypairs that exist
      %{ for k, v in local.validator_keypairs ~}
      %{ if v != "" ~}
      echo '${v}' > /tmp/${k}-keypair.json
      %{ endif ~}
      %{ endfor ~}
      
      # Only store keypairs that exist
      vault kv put secret/solana/validator \
        %{ for k, v in local.validator_keypairs ~}
        %{ if v != "" ~}
        ${k}=@/tmp/${k}-keypair.json \
        %{ endif ~}
        %{ endfor ~}
    EOT
  }
}