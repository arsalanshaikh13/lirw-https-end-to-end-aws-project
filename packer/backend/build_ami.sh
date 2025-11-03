#!/bin/bash
set -exuo pipefail
# Initialize Packer plugins
echo "Initializing Packer plugins..."
packer init .

# Get VPC and subnet information from local Terraform state
# VPC_ID=$(Terraform -chdir=../../terraform/network output -raw vpc_id)
# SUBNET_IDS=$(terraform -chdir=../../terraform/network output -json public_subnet_ids)
# SUBNET_ID=$(echo $SUBNET_IDS | jq -r '.[0]')

# # Get RDS details from Terraform state
# DB_HOST=$(terraform -chdir=../../terraform/database output -raw rds_address)
# DB_PORT="3306"
# DB_USER=$(terraform -chdir=../../terraform/database output -raw rds_username)
# DB_PASSWORD=$(terraform -chdir=../../terraform/database output -raw rds_password)
# RDS_SG_ID=$(terraform -chdir=../../terraform/database output -raw rds_security_group_id)

if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID" ]; then
    echo "Error: Could not retrieve VPC ID or subnet ID from Terraform state"
    exit 1
fi

if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$RDS_SG_ID" ]; then
    echo "Error: Could not retrieve required details from Terraform state"
    exit 1
fi

echo "Using VPC ID: $VPC_ID"
echo "Using Subnet ID: $SUBNET_ID"
echo "Using DB Host: $DB_HOST"
echo "Using DB Port: $DB_PORT"
echo "Using DB User: $DB_USER"
echo "Using RDS Security Group ID: $RDS_SG_ID"
server_key_name=$(terraform -chdir=../../root output -raw server_key_name)
echo "$server_key_name is the name of server key"

# Create security group for Packer
echo "Creating security group for Packer..."
PACKER_SG_ID=$(aws ec2 create-security-group \
    --group-name "packer-sg-$(date +%s)" \
    --description "Security group for Packer build" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

# Add inbound rules to security group
echo "Configuring security group rules..."
aws ec2 authorize-security-group-ingress \
    --group-id "$PACKER_SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Allow access to RDS
echo "Adding access to RDS..."
aws ec2 authorize-security-group-ingress \
    --group-id "$RDS_SG_ID" \
    --protocol tcp \
    --port 3306 \
    --source-group "$PACKER_SG_ID"

echo "Created security group: $PACKER_SG_ID"

# cleanup() {
#   echo "🧹 Cleaning up temporary resources..."
#   if [[ -n "${PACKER_SG_ID:-}" ]]; then
#     echo "Deleting security group $PACKER_SG_ID..."
#     aws ec2 delete-security-group --group-id "$PACKER_SG_ID" || echo "Failed to delete SG or already deleted"
#   fi
# }

cleanup() {
  echo "🧹 Cleaning up temporary resources..."
  if [[ -n "$PACKER_SG_ID" ]]; then

    # Remove RDS access rule
    echo "Removing RDS access rule..."
    aws ec2 revoke-security-group-ingress \
        --group-id "$RDS_SG_ID" \
        --protocol tcp \
        --port 3306 \
        --source-group "$PACKER_SG_ID"

    # Delete security group
    echo "Cleaning up security group..."

    echo "Deleting security group $PACKER_SG_ID..."
    aws ec2 delete-security-group --group-id "$PACKER_SG_ID" || echo "Failed to delete SG or already deleted"
  fi
}

# this is always delete the security group when program exits on error or success
# trap cleanup EXIT ERR
trap cleanup EXIT 


# Get the latest Amazon Linux 2023 AMI ID
SOURCE_AMI=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023.*-arm64" "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text)

# Create a directory for AMI IDs if it doesn't exist
mkdir -p ../../modules/asg/ami_ids

echo "Using latest Amazon Linux 2023 AMI: $SOURCE_AMI"
echo "using the bucket name $bucket_name "

# Build backend AMI
echo "Building backend AMI..."
PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build \
  -var "aws_region=$aws_region" \
  -var "source_ami=$SOURCE_AMI" \
  -var "instance_type=t4g.small" \
  -var "vpc_id=$VPC_ID" \
  -var "subnet_id=$SUBNET_ID" \
  -var "ssh_username=ec2-user" \
  -var "db_host=$DB_HOST" \
  -var "db_port=$DB_PORT" \
  -var "db_user=$DB_USER" \
  -var "db_name=$DB_NAME" \
  -var "db_password=$DB_PASSWORD" \
  -var "security_group_id=$PACKER_SG_ID" \
  -var "s3_ssm_cw_instance_profile_name=$s3_ssm_cw_instance_profile_name" \
  -var "bucket_name=$bucket_name" \
  -var "server_key_name=$server_key_name" \
  backend.pkr.hcl | tee >(grep -Eo 'ami-[a-z0-9]{17}' | tail -n1 > ../../modules/asg/ami_ids/backend_ami.txt)

  

echo "Backend AMI ID has been saved to ../../modules/asg/ami_ids/backend_ami.txt" 




