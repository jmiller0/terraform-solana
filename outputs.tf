# Empty file - all outputs will be removed 

# Network Information
output "vpc_info" {
  description = "VPC information for both cloud providers"
  value = {
    aws = {
      vpc_id = module.networking.aws_vpc_id
    }
    gcp = {
      network_name = module.networking.gcp_network_name
    }
  }
}

# Instance Information
output "instances" {
  description = "Information about all instances"
  value = {
    salt_master = {
      private_ip = module.instances.salt_master_private_ip
      public_ip  = module.instances.salt_master_public_ip
      dns        = module.instances.salt_master_dns
      r53_record = module.instances.route53_records["salt-master"]
    }
    aws = {
      validator = var.create_validators ? {
        private_ip = module.instances.aws_validator_private_ip
        public_ip  = module.instances.aws_validator_public_ip
        dns        = module.instances.aws_validator_dns
        r53_record = module.instances.route53_records["aws-validator"]
      } : null
      test_minion = var.create_test_minions ? {
        private_ip = module.instances.test_minion_aws_private_ip
        public_ip  = module.instances.test_minion_aws_public_ip
        dns        = module.instances.aws_test_minion_dns
        r53_record = module.instances.route53_records["aws-test-minion"]
      } : null
    }
    gcp = {
      validator = var.create_validators ? {
        private_ip = module.instances.gcp_validator_private_ip
        public_ip  = module.instances.gcp_validator_public_ip
        dns        = module.instances.gcp_validator_dns
        r53_record = module.instances.route53_records["gcp-validator"]
      } : null
      test_minion = var.create_test_minions ? {
        private_ip = module.instances.test_minion_gcp_private_ip
        public_ip  = module.instances.test_minion_gcp_public_ip
        dns        = module.instances.gcp_test_minion_dns
        r53_record = module.instances.route53_records["gcp-test-minion"]
      } : null
    }
  }
}

# Connection Information
output "connection_strings" {
  description = "SSH connection strings for all instances"
  value       = module.instances.connection_strings
} 