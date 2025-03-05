output "aws_subnet_id" {
  value = aws_subnet.main.id
}

output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "aws_validator_sg_id" {
  value = aws_security_group.validator.id
}

output "gcp_network_name" {
  value = google_compute_network.main.name
}

output "gcp_subnetwork_name" {
  value = google_compute_subnetwork.main.name
}

output "aws_salt_master_sg_id" {
  value = aws_security_group.salt_master.id
} 