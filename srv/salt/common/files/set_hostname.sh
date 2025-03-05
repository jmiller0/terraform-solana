#!/bin/bash

# Get instance name from metadata
if [ -f /sys/class/dmi/id/product_uuid ] && [ "$(cut -c1-3 /sys/class/dmi/id/product_uuid)" = "ec2" ]; then
    # AWS
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
    NAME_TAG=$(aws ec2 describe-tags --region $REGION --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" --query 'Tags[0].Value' --output text)
else
    # GCP
    NAME_TAG=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
fi

# Set the hostname if we got a valid name
if [ ! -z "$NAME_TAG" ]; then
    hostnamectl set-hostname "$NAME_TAG"
fi 