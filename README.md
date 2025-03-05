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

### Monitoring and Validation
- Comprehensive validation scripts
- Cloud-init status monitoring
- Service health checks
- Log analysis tools

## Directory Structure

```
.
├── modules/
│   └── instances/           # Terraform modules for instance creation
│       ├── salt-master.tf   # Salt master configuration
│       └── templates/       # Cloud-init templates
├── srv/
│   └── salt/               # SaltStack configuration
│       ├── pillar/         # Encrypted pillar data
│       ├── salt-master/    # Salt master states
│       ├── vault/          # Vault configuration
│       └── solana/         # Solana validator states
└── scripts/                # Utility scripts
    ├── sync_salt.sh       # Salt configuration sync
    └── validate_salt_master.sh  # Validation script
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- GCP CLI configured with appropriate credentials
- Access to AWS and GCP accounts
- Solana validator keypairs
- GPG for encrypting sensitive data

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd terraform-solana
   ```

2. Configure your cloud provider credentials:
   - AWS: Configure using `aws configure`
   - GCP: Configure using `gcloud auth application-default login`

3. Set up GPG encryption for sensitive data:
   ```bash
   # Generate a new GPG key if you don't have one
   gpg --gen-key
   
   # Export your public key
   gpg --export --armor your-email@example.com > gpg.pub
   ```

4. Create your terraform.tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit terraform.tfvars with your specific values.

5. Place your Solana validator keypairs in the `validator-keys` directory:
   - authorized-withdrawer-keypair.json
   - stake-keypair.json
   - validator-keypair.json
   - vote-account-keypair.json

6. Initialize Terraform:
   ```bash
   terraform init
   ```

7. Review the planned changes:
   ```bash
   terraform plan
   ```

8. Apply the configuration:
   ```bash
   terraform apply
   ```

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

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[Your License Here]

