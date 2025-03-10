#!/bin/bash
set -e

# Skip terraform init if we're in CI or if SKIP_INIT is set
if [[ -z "${CI}" && -z "${SKIP_INIT}" && ! -d ".terraform" ]]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Execute the command passed to docker run
exec "$@" 