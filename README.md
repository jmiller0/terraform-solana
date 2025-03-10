# Terraform Solana Infrastructure

This project automates the deployment and management of a Solana validator infrastructure using Terraform, SaltStack, and HashiCorp Vault. It provides a secure, scalable, and maintainable way to deploy Solana validators across multiple cloud providers (AWS and GCP).

## Architecture Overview

The infrastructure consists of several key components:

### 1. Salt Master Server
- Central configuration management server
- Runs HashiCorp Vault for secrets management
- Manages all validator and test minion configurations
- Handles GPG encryption for sensitive data
- Provides secure communication channel for all minions

### 2. Validator Nodes
- Runs Solana validator software
- Configured with optimal system settings for validator performance
- Securely retrieves keypairs from Vault
- Supports both AWS and GCP deployments

### 3. Test Minions
- Small test instances for validating Salt configurations
- Separate security policies from validator nodes
- Useful for testing and development

## Key Features

### Security
- TLS encryption for all Vault communications
- GPG encryption for sensitive pillar data
- AppRole authentication for Vault access
- Secure keypair management
- IAM roles and policies for cloud provider access
- OIDC authentication for GitHub Actions

### Configuration Management
- Centralized SaltStack configuration
- Environment-specific pillar data
- Automated system tuning for validator performance
- Consistent configuration across all nodes

### Secrets Management
- HashiCorp Vault for secure secrets storage
- Encrypted keypair storage
- Role-based access control
- Secure credential distribution

### CI/CD with GitHub Actions
- Automated Terraform plan on pull requests
- Plan verification before apply
- Secure cloud credentials handling via OIDC
- Label-driven workflow (`plan` and `apply` labels)
- Automated plan output as PR comments
- State locking during operations

### State Management
- Remote state stored in AWS S3
- State locking via DynamoDB
- Encrypted state storage
- State file location: `s3://terraform-state-solana-validator/terraform.tfstate`
- Lock table: `terraform-state-lock`

### Monitoring and Validation
- Comprehensive validation scripts
- Cloud-init status monitoring
- Service health checks
- Log analysis tools

## Directory Structure

```
.
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # PR plan workflow
│       └── terraform-apply.yml   # Changes apply workflow
├── modules/
│   ├── iam/                     # IAM roles and policies
│   │   └── github_actions.tf    # GitHub Actions OIDC configuration
│   ├── instances/              # Instance creation and configuration
│   ├── networking/             # Network and security group configurations
│   └── storage/               # Storage and backup configurations
├── srv/
│   └── salt/                  # SaltStack configuration
│       ├── common/            # Common Salt states and files
│       ├── pillar/            # Encrypted pillar data
│       ├── reactor/           # Salt reactor configurations
│       ├── salt-master/       # Salt master states
│       ├── solana/            # Solana validator states
│       ├── vault/             # Vault configuration
│       ├── common.sls         # Common system configuration
│       ├── salt_init.sls      # Salt initialization
│       ├── top.sls            # Salt top file
│       ├── vault_init.sls     # Vault initialization
│       └── vault_test.sls     # Vault testing
├── scripts/                   # Utility scripts
│   └── setup.sh              # Setup and initialization script
├── validator-keys/           # Solana validator keypairs
├── main.tf                  # Main Terraform configuration
├── variables.tf             # Terraform variables
├── outputs.tf               # Terraform outputs
├── providers.tf             # Provider configurations
└── terraform.tfvars.example # Example variables file
```

## Prerequisites

- Terraform >= 1.11.1
- AWS CLI configured with appropriate credentials
- GCP CLI configured with appropriate credentials
- Access to AWS and GCP accounts
- Solana validator keypairs
- GPG for encrypting sensitive data
- Public IP address (will be automatically detected or can be manually provided)
- GitHub repository for CI/CD workflows

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd terraform-solana
   ```

2. Configure your cloud provider credentials:
   - AWS: Configure using `aws configure`
   - GCP: Configure using `gcloud auth application-default login`

3. Run the setup script:
   ```bash
   ./scripts/setup.sh init
   ```
   This will:
   - Create terraform.tfvars from the example file
   - Add your SSH public key (from ~/.ssh/id_rsa.pub or prompt for input)
   - Add your GCP project ID
   - Add your root zone
   - Verify cloud provider credentials
   - Enable required GCP APIs
   - Initialize Terraform

4. Configure GitHub Actions:
   - Add required secrets to your GitHub repository:
     - `AWS_ACCOUNT_ID`
     - `ADMIN_IP`
     - `AWS_ROOT_ZONE`
     - `AWS_ZONE_ID`
     - `GCP_PROJECT_ID`
     - `SSH_PUBLIC_KEY`
     - `WORKLOAD_IDENTITY_PROVIDER`
     - `GCP_SERVICE_ACCOUNT_EMAIL`

5. Making Changes:
   - Create a new branch and make your changes
   - Create a pull request
   - Add the `plan` label to trigger a Terraform plan
   - Review the plan output in the PR comments
   - If satisfied, add the `apply` label to apply changes
   - Changes will only be applied if the plan was successful

## Post-Deployment Steps

1. Verify Salt master deployment:
   ```bash
   # SSH into the salt master
   ssh ubuntu@salt-master.your-domain.com
   
   # Check Salt master status
   sudo systemctl status salt-master
   sudo systemctl status vault
   ```

2. Verify validator deployment:
   ```bash
   # SSH into a validator
   ssh ubuntu@validator-0.your-domain.com
   
   # Check validator status
   sudo systemctl status solana-validator
   ```

3. Monitor logs:
   ```bash
   # On salt master
   journalctl -u salt-master -f
   
   # On validator
   journalctl -u solana-validator -f
   ```

## Security Considerations

- All sensitive data is encrypted at rest
- Vault is configured with TLS
- Keypairs are stored securely in Vault
- Access is controlled through AppRole authentication
- System configurations follow security best practices
- Sensitive files are excluded from git tracking
- GPG encryption for pillar data
- Secure keypair management
- OIDC authentication for GitHub Actions
- Encrypted state storage in S3
- State locking via DynamoDB
- Secure cloud credentials management

## Troubleshooting

1. Salt master connectivity issues:
   - Check security groups and network ACLs
   - Verify DNS resolution
   - Check Salt master logs

2. Validator issues:
   - Check system resources (CPU, memory, disk)
   - Verify keypair permissions
   - Check validator logs

3. Vault issues:
   - Verify TLS certificates
   - Check Vault status and logs
   - Verify AppRole configuration

4. GitHub Actions issues:
   - Check workflow run logs
   - Verify repository secrets
   - Ensure OIDC provider is configured correctly
   - Verify IAM roles and permissions

5. State file issues:
   - Check S3 bucket permissions
   - Verify DynamoDB table access
   - Check for state locks
   - Review Terraform backend configuration

