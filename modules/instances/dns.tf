# AWS Validator DNS Records
resource "aws_route53_record" "aws_validator" {
  count = var.create_aws_instances && var.create_validators ? 1 : 0
  
  zone_id = var.hosted_zone_id
  name    = "solana-validator-aws-${count.index}.${var.aws_root_zone}"
  type    = "A"
  ttl     = "60"
  records = aws_instance.validator[count.index].instance_state == "running" ? [aws_instance.validator[count.index].public_ip] : []

  # lifecycle {
  #   ignore_changes = [records]
  # }
}

# DNS record for Salt Master
resource "aws_route53_record" "salt_master" {
  zone_id = var.hosted_zone_id
  name    = "salt-master.${var.aws_root_zone}"
  type    = "A"
  ttl     = "60"  # Lower TTL for faster updates
  records = [aws_instance.salt_master.public_ip]

  lifecycle {
    ignore_changes = [records]
  }
}

# Route53 record for GCP validator
resource "aws_route53_record" "gcp_validator_node" {
  count = var.create_gcp_instances && var.create_validators ? 1 : 0
  
  zone_id = var.hosted_zone_id
  name    = "solana-validator-gcp-${count.index}.${var.aws_root_zone}"
  type    = "A"
  ttl     = "300"
  records = [google_compute_instance.validator[count.index].network_interface[0].access_config[0].nat_ip]
  depends_on = [google_compute_instance.validator]
}

# AWS Test Minion DNS Record
resource "aws_route53_record" "aws_test_minion" {
  count = var.create_aws_instances && var.create_test_minions ? 1 : 0
  
  zone_id = var.hosted_zone_id
  name    = "aws-test-minion.${var.aws_root_zone}"
  type    = "A"
  ttl     = "60"
  records = aws_instance.test_minion[count.index].instance_state == "running" ? [aws_instance.test_minion[count.index].public_ip] : []
}

# GCP Test Minion DNS Record
resource "aws_route53_record" "gcp_test_minion" {
  count = var.create_gcp_instances && var.create_test_minions ? 1 : 0
  
  zone_id = var.hosted_zone_id
  name    = "gcp-test-minion.${var.aws_root_zone}"
  type    = "A"
  ttl     = "60"
  records = [google_compute_instance.test_minion[count.index].network_interface[0].access_config[0].nat_ip]
  depends_on = [google_compute_instance.test_minion]
}

