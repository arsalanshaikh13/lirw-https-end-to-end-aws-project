#!/usr/bin/bash
set -exuo pipefail
if [ "$#" -gt 0 ]; then
  terraform apply -target="$1"
  exit 1
fi
# git clone https://github.com/pandacloud1/AWS_Project1.git application-code
# # Function to check if a command exists
# check_command() {
#     if ! command -v $1 &> /dev/null; then
#         echo "Error: $1 is required but not installed."
#         exit 1
#     fi
# }

# # Check required tools
# check_command terraform
# check_command packer
# check_command aws
# check_command jq

# Function to print section headers
print_section() {
    echo "================================================"
    echo " $1"
    echo "================================================"
}

# running the functions in subshell
(
  # setup terraform state bucket
  cd backend-tfstate-bootstrap
  DIRECTORY_BACKEND=".terraform"

  if [ -d "$DIRECTORY_BACKEND" ] ; then
    echo "Directory '$DIRECTORY_BACKEND' exists."
    if grep -q '"resources": \[\]' terraform.tfstate; then
      print_section "Creating terraform state backend bucket and table"
      echo "tfstate does not contains resources."
      terraform init -reconfigure -upgrade
      terraform fmt
      terraform validate
      # terraform apply -auto-approve -parallelism=20 -refresh=false
      terraform apply -auto-approve -parallelism=20 -refresh=false
    fi
    echo "tfstate does  contain resources."

  else
    echo "Directory '$DIRECTORY_BACKEND' does not exist."
    print_section "Creating terraform state backend bucket and table"
    echo "Setting up Terraform state bucket and DyanmoDB Table"

    terraform init -reconfigure
    terraform fmt
    terraform validate
    terraform apply -auto-approve -parallelism=20 -refresh=false
  fi
) #subshell ended

# exit 1
# cd ..
#  Generate SSH keys
# Function to check if local key files exist
check_local_keys() {
    local key_name=$1
    [ -f "$key_name" ] && [ -f "$key_name.pub" ]
    return $?
}

make_ssh_keys(){
print_section "Generating SSH keys"

cd terraform/permissions/modules/key
# mkdir -p key
# cd key
if ! check_local_keys "nat-bastion"; then
    echo "Creating backend key pair..."
    ssh-keygen -t rsa -b 4096 -f nat-bastion -N ""
else
    echo "nat-bastion key pair already exists locally"
fi
echo "nat-bastion SSH key pairs setup completed"

# Generate frontend key pair if it doesn't exist
if ! check_local_keys "client_key"; then
    echo "Creating client key pair..."
    ssh-keygen -t rsa -b 4096 -f client_key -N ""
else
    echo "Client key pair already exists locally"
fi

if ! check_local_keys "server_key"; then
    echo "Creating server key pair..."
    ssh-keygen -t rsa -b 4096 -f server_key -N ""
else
    echo "Server key pair already exists locally"
fi

echo "SSH key pairs setup completed"
# cd ../..
}
# running generating ssh function in subshell
(
  make_ssh_keys
)


# ( # subshell started
# cd root

# DIRECTORY="lirw-three-tier"

# if [ -d "$DIRECTORY" ]; then
#   echo "Directory '$DIRECTORY' exists."
# else
#   echo "Directory '$DIRECTORY' does not exist."
#   git clone -b feature/add-logging https://github.com/Learn-It-Right-Way/lirw-react-node-mysql-app.git lirw-three-tier
# fi
# Create S3 bucket and dynamodb for Terraform state if it doesn't exist
# echo "Setting up Terraform state bucket"
# AWS_REGION="us-east-1"
# BUCKET_NAME="panda-backend"
# if ! aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
#     echo "Creating S3 bucket for Terraform state..."
#     if [ "$AWS_REGION" = "us-east-1" ]; then
#         # us-east-1 doesn't support LocationConstraint
#         aws s3api create-bucket \
#             --bucket $BUCKET_NAME \
#             --region $AWS_REGION
#     else
#         aws s3api create-bucket \
#             --bucket $BUCKET_NAME \
#             --region $AWS_REGION \
#             --create-bucket-configuration LocationConstraint=$AWS_REGION
#     fi
#     aws s3api put-bucket-versioning \
#         --bucket $BUCKET_NAME \
#         --versioning-configuration Status=Enabled
# else
#     echo "s3 bucket '$BUCKET_NAME' exists."
# fi

# echo "Setting up Terraform state DyanmoDB Table"
# # Create  dynamodb for Terraform state if it doesn't exist
# TABLE_NAME="panda-lock-table"
# if aws dynamodb describe-table --table-name $TABLE_NAME > /dev/null 2>&1; then
#     echo "Table '$TABLE_NAME' exists."
# else
#     echo "Table '$TABLE_NAME' does not exist."
#     echo "Creating dynamodb table for Terraform state..."
#     aws dynamodb create-table \
#         --table-name $TABLE_NAME \
#         --attribute-definitions AttributeName=LockID,AttributeType=S \
#         --key-schema AttributeName=LockID,KeyType=HASH \
#         --billing-mode PAY_PER_REQUEST

# fi
# ) # subshell ended


# convert CRLF to LF if needed
# List of files to check
files=("packer/backend/server.sh" "packer/frontend/client.sh")

# Loop through each file
for file_to_check in "${files[@]}"; do
    if grep -q $'\r' "$file_to_check"; then
        echo "$file_to_check uses CRLF line endings"
        echo "converting CRLF line endings to LF line endings for file $file_to_check"
        dos2unix packer/backend/server.sh
        dos2unix packer/frontend/client.sh

    else
        echo "$file_to_check uses LF line endings"
    fi
done

cd terraform

# Path to the parent folder
# parent_dir="terraform"
parent_dir=("network" "permissions" "database" "compute" "hosting")
print_line=("Creating VPC, security_group, s3 modules" 
            "Creating iam_role, acm, key_pair modules"
            "Creating database, ssm_param modules"
            "creating alb, asg modules"
            "creating cloudfront, route53 modules")

count=0
# Loop through each folder inside the terraform directory
# for folder in "$parent_dir"/*; do
for folder in "${parent_dir[@]}"; do
  # if [[ "$folder" == "network" ]]; then
  if [[ "$folder" == "network" || "$folder" == "permissions" || "$folder" == "database" || "$folder" == "compute"  ]]; then
    echo "The folder is network."
    count=$((count + 1))
    continue
  fi
  if [ -d "$folder" ]; then
    # Start a subshell
    (
      echo "Performing operation in $folder"
      
      # Change into the folder
      cd "$folder" || exit
      
      # Print the line from the array
      print_section "${print_line[$count]}"
      
         
      # terraform force-unlock  e1c2ae9c-176a-2ce3-48b3-673189635e65
      # Perform the operation you need
      # source env.sh
      if [ ! -f ".terraform.lock*" ]; then
        terraform init -reconfigure
        terraform fmt
        terraform validate
      fi
      
      if [ ! -d "graph" ]; then
        mkdir -p graph
        terraform plan -out=graph/plan-lirw-2.out 
        terraform show -json graph/plan-lirw-2.out > graph/plan-lirw-2.json
        # terraform apply -auto-approve -parallelism=20 

        # terraform graph > graph/graph-lirw-2.txt
      fi
      # terraform apply -auto-approve -parallelism=20 -refresh=false
      terraform apply -auto-approve -parallelism=20 
      terraform graph > graph/graph2.txt

      
      # Go back to the parent directory
      # cd - || exit # no need for this since i am running a subshell

    ) # Subshell exits, you are automatically back in $parent_dir
    # # Increment count
    count=$((count + 1))

    # # Check if we've exhausted the array
    # if [ $count -ge ${#print_line[@]} ]; then
    #   echo "count greater than print_line array"
    #   break
    # fi
  fi
done


# ./startup.sh 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' > logs/setupnew.log )