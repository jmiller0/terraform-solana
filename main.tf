# Organize module structure
module "networking" {
  source     = "./modules/networking"
  gcp_region = var.gcp_region
  aws_region = var.aws_region

  # These variables must be declared in modules/networking/variables.tf
  aws_vpc_cidr   = var.aws_vpc_cidr
  gcp_vpc_cidr   = var.gcp_vpc_cidr
  admin_ip       = var.admin_ip
  gcp_project_id = var.gcp_project_id
}

# GitHub Actions OIDC and IAM roles configuration
module "iam" {
  source = "./modules/iam"

  github_username = var.github_username
  github_repo     = var.github_repo
  aws_region      = var.aws_region # Using root variable
  hosted_zone_id  = var.aws_zone_id
  gcp_project_id  = var.gcp_project_id
}

module "instances" {
  source     = "./modules/instances"
  gcp_region = var.gcp_region
  gcp_zone   = var.gcp_zone

  depends_on = [module.networking, module.iam]

  # These variables must be declared in modules/instances/variables.tf
  ssh_public_key = var.ssh_public_key
  subnet_id      = module.networking.aws_subnet_id
  vpc_id         = module.networking.aws_vpc_id
  aws_root_zone  = var.aws_root_zone
  hosted_zone_id = var.aws_zone_id

  aws_security_group_id = module.networking.aws_validator_sg_id
  aws_salt_master_sg_id = module.networking.aws_salt_master_sg_id
  gcp_network_name      = module.networking.gcp_network_name
  gcp_subnetwork_name   = module.networking.gcp_subnetwork_name
  gcp_vpc_cidr          = var.gcp_vpc_cidr
  create_validators     = var.create_validators
  create_test_minions   = var.create_test_minions
  create_gcp_instances  = var.create_gcp_instances
  create_aws_instances  = var.create_aws_instances
  gcp_project_id        = var.gcp_project_id

  # IAM configuration
  validator_instance_profile_name   = module.iam.validator_instance_profile_name
  salt_master_instance_profile_name = module.iam.salt_master_instance_profile_name
  validator_service_account_email   = module.iam.validator_service_account_email
}

module "storage" {
  source = "./modules/storage"

  aws_vpc_cidr              = var.aws_vpc_cidr
  gcp_vpc_cidr              = var.gcp_vpc_cidr
  admin_ip                  = var.admin_ip
  validator_instance_role   = module.iam.validator_role_arn
  validator_service_account = module.instances.validator_service_account
  gcp_region                = var.gcp_region
  salt_master_instance_role = module.iam.salt_master_role_arn
  aws_root_zone             = var.aws_root_zone
  common_labels             = local.common_labels
} 