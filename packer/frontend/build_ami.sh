#!/bin/bash
set -euo pipefail

# Initialize Packer plugins
echo "Initializing Packer plugins..."
packer init .

# get VPC and subnet information from local Terraform state
# VPC_ID=$(Terraform -chdir=../../terraform/network output -raw vpc_id)
# SUBNET_IDS=$(terraform -chdir=../../terraform/network output -json public_subnet_ids)
# SUBNET_ID=$(echo $SUBNET_IDS | jq -r '.[0]')

if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID" ]; then
    echo "Error: Could not retrieve VPC ID or subnet ID from Terraform state"
    exit 1
fi

echo "Using VPC ID: $VPC_ID"
echo "Using Subnet ID: $SUBNET_ID"

client_key_name=$(terraform -chdir=../../root output -raw client_key_name)
# client_key_name="client_key"

# Get the latest Amazon Linux 2023 AMI ID 
SOURCE_AMI=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023.*-arm64" "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text)

echo "Using latest Amazon Linux 2023 AMI: $SOURCE_AMI"

# Create a directory for AMI IDs if it doesn't exist
# mkdir -p ../../terraform/compute/ami_ids
mkdir -p ../../modules/asg/ami_ids

# Build frontend AMI
echo "Building frontend AMI..."
PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build \
  -var "aws_region=$aws_region" \
  -var "source_ami=$SOURCE_AMI" \
  -var "instance_type=t4g.small" \
  -var "vpc_id=$VPC_ID" \
  -var "ssh_username=ec2-user" \
  -var "subnet_id=$SUBNET_ID" \
  -var "s3_ssm_cw_instance_profile_name=$s3_ssm_cw_instance_profile_name" \
  -var "bucket_name=$bucket_name" \
  -var "internal_alb_dns_name=$internal_alb_dns_name" \
  -var "client_key_name=$client_key_name" \
  frontend.pkr.hcl | tee >(grep -Eo 'ami-[a-z0-9]{17}'| tail -n1 > ../../modules/asg/ami_ids/frontend_ami.txt)
  # frontend.pkr.hcl | tee >(grep -Eo 'ami-[a-z0-9]{17}'| tail -n1 > ../../terraform/compute/ami_ids/frontend_ami.txt)

# echo "Frontend AMI ID has been saved to ../../terraform/compute/ami_ids/frontend_ami.txt" 
echo "Frontend AMI ID has been saved to ../../modules/asg/ami_ids/frontend_ami.txt" 
