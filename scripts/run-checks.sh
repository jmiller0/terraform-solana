#!/bin/bash

# Exit on any error
set -e

echo "Running local checks..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo -e "\n${GREEN}=== $1 ===${NC}\n"
}

# Check if required tools are installed
check_dependencies() {
    print_section "Checking dependencies"
    
    local missing_deps=0
    
    # Check for terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}terraform is not installed${NC}"
        missing_deps=1
    fi
    
    # Check for tflint
    if ! command -v tflint &> /dev/null; then
        echo -e "${RED}tflint is not installed${NC}"
        missing_deps=1
    fi
    
    # Check for salt-lint
    if ! command -v salt-lint &> /dev/null; then
        echo -e "${RED}salt-lint is not installed${NC}"
        missing_deps=1
    fi
    
    # Check for python3
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}python3 is not installed${NC}"
        missing_deps=1
    fi
    
    if [ $missing_deps -eq 1 ]; then
        echo -e "\n${RED}Please install missing dependencies before running checks${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies are installed${NC}"
}

# Run Terraform checks
run_terraform_checks() {
    print_section "Running Terraform checks"
    
    echo "Running terraform fmt check..."
    terraform fmt -check -recursive || {
        echo -e "${RED}Terraform format check failed. Run 'terraform fmt -recursive' to fix formatting${NC}"
        return 1
    }
    
    echo "Running terraform init..."
    terraform init -backend=false
    
    echo "Running terraform validate..."
    terraform validate
    
    echo "Running tflint..."
    tflint --init
    tflint -f compact
    
    echo -e "${GREEN}All Terraform checks passed${NC}"
}

# Run Salt checks
run_salt_checks() {
    print_section "Running Salt checks"
    
    echo "Running salt-lint..."
    cd ./srv/salt || exit 1
    salt-lint -v -x 205 ./**/*.sls
    
    echo "Checking YAML syntax..."
    find . -name "*.yml" -o -name "*.yaml" | while read -r file; do
        echo "Checking $file..."
        python3 -c "import yaml; yaml.safe_load(open('$file'))"
    done
    cd - || exit 1
    
    echo -e "${GREEN}All Salt checks passed${NC}"
}

# Main execution
main() {
    check_dependencies
    run_terraform_checks
    run_salt_checks
    
    print_section "All checks completed successfully! 🎉"
}

main 