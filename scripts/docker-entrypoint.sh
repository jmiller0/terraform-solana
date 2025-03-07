#!/bin/bash
set -e

# Initialize Terraform if .terraform directory doesn't exist
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Execute the command passed to docker run
exec "$@" 