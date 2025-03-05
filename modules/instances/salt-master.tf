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
  }

  user_data = data.cloudinit_config.salt_master.rendered

  tags = {
    Name = "salt-master"
    Role = "salt-master"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

# # Ensure Salt Master is running
# resource "null_resource" "ensure_salt_master_running" {
#   triggers = {
#     instance_id = aws_instance.salt_master.id
#   }

#   provisioner "local-exec" {
#     command = <<-EOF
#       INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids ${aws_instance.salt_master.id} --query 'Reservations[0].Instances[0].State.Name' --output text)
#       if [ "$INSTANCE_STATE" != "running" ]; then
#         echo "Starting Salt Master instance..."
#         aws ec2 start-instances --instance-ids ${aws_instance.salt_master.id}
#         aws ec2 wait instance-running --instance-ids ${aws_instance.salt_master.id}
#       fi
#     EOF
#   }
# }

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
  # Read keypairs directly from local directory
  validator_keypairs = {
    "authorized-withdrawer" = file("./validator-keys/authorized-withdrawer-keypair.json")
    "stake" = file("./validator-keys/stake-keypair.json")
    "validator" = file("./validator-keys/validator-keypair.json")
    "vote-account" = file("./validator-keys/vote-account-keypair.json")
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

  # Part 2: Store keypairs in Vault
  part {
    filename     = "store-keypairs.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOT
      #!/bin/bash
      export VAULT_SKIP_VERIFY=true
      export VAULT_ADDR="https://127.0.0.1:8200"
      export VAULT_TOKEN=$(cat /etc/salt/vault_token)
      # Write keypairs to /tmp first
      %{ for k, v in local.validator_keypairs ~}
      echo '${v}' > /tmp/${k}-keypair.json
      %{ endfor ~}
      
      # Store all keypairs in a single vault kv put command
      vault kv put secret/solana/validator \
        %{ for k, v in local.validator_keypairs ~}
        ${k}=@/tmp/${k}-keypair.json \
        %{ endfor ~}
    EOT
  }
}