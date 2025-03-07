# Salt Master Information
output "salt_master_public_ip" {
  description = "Public IP of Salt master"
  value       = aws_instance.salt_master.public_ip
}

output "salt_master_private_ip" {
  description = "Private IP of Salt master"
  value       = aws_instance.salt_master.private_ip
}

output "salt_master_dns" {
  description = "Public DNS of Salt master"
  value       = aws_instance.salt_master.public_dns
}

# AWS Instance Information
output "aws_validator_private_ip" {
  description = "Private IP of AWS validator"
  value       = var.create_aws_instances && var.create_validators ? aws_instance.validator[0].private_ip : null
}

output "aws_validator_public_ip" {
  description = "Public IP of AWS validator"
  value       = var.create_aws_instances && var.create_validators ? aws_instance.validator[0].public_ip : null
}

output "aws_validator_dns" {
  description = "Public DNS of AWS validator"
  value       = try(aws_instance.validator[0].public_dns, null)
}

output "test_minion_aws_private_ip" {
  description = "Private IP of AWS test minion"
  value       = try(aws_instance.test_minion[0].private_ip, null)
}

output "test_minion_aws_public_ip" {
  description = "Public IP of AWS test minion"
  value       = try(aws_instance.test_minion[0].public_ip, null)
}

output "aws_test_minion_dns" {
  description = "Public DNS of AWS test minion"
  value       = try(aws_instance.test_minion[0].public_dns, null)
}

# GCP Instance Information
output "gcp_validator_private_ip" {
  description = "Private IP of GCP validator"
  value       = var.create_gcp_instances && var.create_validators ? google_compute_instance.validator[0].network_interface[0].network_ip : null
}

output "gcp_validator_public_ip" {
  description = "Public IP of GCP validator"
  value       = var.create_gcp_instances && var.create_validators ? google_compute_instance.validator[0].network_interface[0].access_config[0].nat_ip : null
}

output "gcp_validator_dns" {
  description = "Public DNS of GCP validator"
  value       = try(google_compute_instance.validator[0].network_interface[0].access_config[0].nat_ip, null)
}

output "test_minion_gcp_private_ip" {
  description = "Private IP of GCP test minion"
  value       = try(google_compute_instance.test_minion[0].network_interface[0].network_ip, null)
}

output "test_minion_gcp_public_ip" {
  description = "Public IP of GCP test minion"
  value       = try(google_compute_instance.test_minion[0].network_interface[0].access_config[0].nat_ip, null)
}

output "gcp_test_minion_dns" {
  description = "Public DNS of GCP test minion"
  value       = try(google_compute_instance.test_minion[0].network_interface[0].access_config[0].nat_ip, null)
}

output "gcp_validator_data_disk_id" {
  description = "ID of GCP validator data disk"
  value       = (var.create_validators && var.create_gcp_instances) ? google_compute_disk.validator_data[0].id : null
}

# Service Account Information
output "validator_service_account" {
  description = "GCP service account email for validator"
  value       = google_service_account.validator.email
}

# DNS Records
output "route53_records" {
  description = "All Route53 records for the configured root zone"
  value = {
    "salt-master" = {
      fqdn = aws_route53_record.salt_master.name
      ip   = aws_instance.salt_master.public_ip
    }
    "aws-validator" = (var.create_aws_instances && var.create_validators) ? {
      fqdn = aws_route53_record.aws_validator[0].name
      ip   = aws_instance.validator[0].public_ip
    } : null
    "gcp-validator" = (var.create_gcp_instances && var.create_validators) ? {
      fqdn = aws_route53_record.gcp_validator_node[0].name
      ip   = google_compute_instance.validator[0].network_interface[0].access_config[0].nat_ip
    } : null
    "aws-test-minion" = (var.create_aws_instances && var.create_test_minions) ? {
      fqdn = aws_route53_record.aws_test_minion[0].name
      ip   = aws_instance.test_minion[0].public_ip
    } : null
    "gcp-test-minion" = (var.create_gcp_instances && var.create_test_minions) ? {
      fqdn = aws_route53_record.gcp_test_minion[0].name
      ip   = google_compute_instance.test_minion[0].network_interface[0].access_config[0].nat_ip
    } : null
  }
}

# Connection Information
output "connection_strings" {
  description = "SSH connection strings for all instances"
  value = {
    salt_master = "ubuntu@${aws_instance.salt_master.public_dns}"
    aws_minion  = try("ubuntu@${aws_instance.test_minion[0].public_dns}", null)
    gcp_minion  = try("ubuntu@${google_compute_instance.test_minion[0].network_interface[0].access_config[0].nat_ip}", null)
  }
} 