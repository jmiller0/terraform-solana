#!/bin/bash
set -e  # Exit on any error

# Check for required tools and credentials
initial_setup() {
    echo "Stage 1: Initial Setup..."

    # Handle terraform.tfvars
    if [ ! -f terraform.tfvars ]; then
        echo "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
    fi

    # Check and add admin IP if needed
    if ! grep -q "admin_ip" terraform.tfvars; then
        echo "Detecting your public IP address..."
        PUBLIC_IP=$(curl -s https://api.ipify.org)
        if [ -z "$PUBLIC_IP" ]; then
            echo "Failed to detect public IP address automatically."
            read -p "Please enter your public IP address: " PUBLIC_IP
        fi
        echo "Adding admin_ip to terraform.tfvars..."
        echo "admin_ip = \"$PUBLIC_IP/32\"" >> terraform.tfvars
    else
        echo "admin_ip already exists in terraform.tfvars"
    fi

    # Check and add SSH public key if needed
    if ! grep -q "ssh_public_key" terraform.tfvars; then
        if [ -f ~/.ssh/id_rsa.pub ]; then
            echo "Adding ssh_public_key from ~/.ssh/id_rsa.pub to terraform.tfvars..."
            echo "ssh_public_key = \"$(cat ~/.ssh/id_rsa.pub)\"" >> terraform.tfvars
        else
            echo "No SSH public key found at ~/.ssh/id_rsa.pub"
            read -p "Please enter your SSH public key: " ssh_key
            echo "ssh_public_key = \"$ssh_key\"" >> terraform.tfvars
        fi
    else
        echo "ssh_public_key already exists in terraform.tfvars"
    fi

    # Check and add GCP project ID if needed
    if ! grep -q "gcp_project_id" terraform.tfvars; then
        read -p "Please enter your GCP project ID: " gcp_project_id
        echo "gcp_project_id = \"$gcp_project_id\"" >> terraform.tfvars
    else
        echo "gcp_project_id already exists in terraform.tfvars"
    fi

    # Check and add root zone if needed
    if ! grep -q "root_zone" terraform.tfvars; then
        read -p "Please enter your root zone (e.g., example.com): " root_zone
        echo "root_zone = \"$root_zone\"" >> terraform.tfvars
    else
        echo "root_zone already exists in terraform.tfvars"
    fi

    # Check for required tools
    command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }
    command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required but not installed. Aborting." >&2; exit 1; }
    command -v gcloud >/dev/null 2>&1 || { echo "Google Cloud SDK is required but not installed. Aborting." >&2; exit 1; }

    # Verify AWS and GCP credentials
    echo "Verifying AWS credentials..."
    aws sts get-caller-identity >/dev/null || { echo "AWS credentials not configured. Please run 'aws configure' first." >&2; exit 1; }

    echo "Verifying GCP credentials..."
    if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
        echo "GCP application default credentials not configured."
        echo "Please run 'gcloud auth application-default login' first."
        exit 1
    fi

    # Get GCP project ID from terraform.tfvars
    GCP_PROJECT_ID=$(grep 'gcp_project_id' terraform.tfvars | cut -d'"' -f2)

    # Check GCP billing
    echo "Checking GCP billing status..."
    if ! gcloud billing projects describe "$GCP_PROJECT_ID" >/dev/null 2>&1; then
        echo "GCP billing not enabled for project $GCP_PROJECT_ID"
        echo "Please enable billing at:"
        echo "https://console.cloud.google.com/billing/linkedaccount?project=$GCP_PROJECT_ID"
        echo "Or run: gcloud billing projects link $GCP_PROJECT_ID --billing-account=YOUR_BILLING_ACCOUNT_ID"
        exit 1
    fi

    echo "Enabling required GCP APIs..."
    gcloud services enable compute.googleapis.com --project="$GCP_PROJECT_ID" || {
        echo "Failed to enable Compute Engine API. Please enable it manually at:"
        echo "https://console.developers.google.com/apis/api/compute.googleapis.com/overview?project=$GCP_PROJECT_ID"
        exit 1
    }

    # Initialize Terraform
    echo "Initializing Terraform..."
    terraform init

    echo "Initial setup complete!"
}

# Generate and show Terraform plan
generate_plan() {
    echo "Stage 2: Generating Terraform Plan..."

    # Validate Terraform configuration
    echo "Validating Terraform configuration..."
    terraform validate

    # Show the plan
    echo "Generating Terraform plan..."
    terraform plan -out=tfplan

    echo "Plan generated! Review the plan above and run 'terraform apply tfplan' to deploy"
}

# Main execution
case "$1" in
    init)
        initial_setup
        ;;
    plan)
        generate_plan
        ;;
    all)
        initial_setup
        generate_plan
        ;;
    *)
        echo "Usage: $0 {init|plan|all}"
        echo "  init - Run initial setup only"
        echo "  plan - Generate Terraform plan only"
        echo "  all  - Run both setup and plan"
        exit 1
        ;;
esac 