#!/bin/bash
set -eo pipefail
( # subshell started
    #  1. Clean up AMIs
    # print_section "Cleaning up AMIs"
    # echo "Cleaning up AMIs"

    # # Get AMI IDs from the files if they exist
    # export AWS_REGION="us-east-1"
    # FRONTEND_AMI_ID=""
    # BACKEND_AMI_ID=""

    # if [ -f "terraform/compute/modules/asg/ami_ids/frontend_ami.txt" ]; then
    #     FRONTEND_AMI_ID=$(cat terraform/compute/modules/asg/ami_ids/frontend_ami.txt)
    # fi

    # if [ -f "terraform/compute/modules/asg/ami_ids/frontend_ami.txt" ]; then
    #     BACKEND_AMI_ID=$(cat terraform/compute/modules/asg/ami_ids/backend_ami.txt)
    # fi

    # # Deregister AMIs if they exist
    # if [ ! -z "$FRONTEND_AMI_ID" ]; then
    #     echo "Deregistering Frontend AMI: $FRONTEND_AMI_ID"

    #     echo "Finding and deleting associated snapshots..."
    #     snapshot_ids=$(aws ec2 describe-images \
    #         --image-ids "$FRONTEND_AMI_ID" \
    #         --region "$AWS_REGION" \
    #         --query "Images[0].BlockDeviceMappings[].Ebs.SnapshotId" \
    #         --output text 2>/dev/null)

    #     aws ec2 deregister-image --image-id $FRONTEND_AMI_ID
    #     if [ -n "$snapshot_ids" ]; then
    #         for snap_id in $snapshot_ids; do
    #             if [ -n "$snap_id" ]; then
    #                 echo "Deleting snapshot: $snap_id"
    #                 aws ec2 delete-snapshot --snapshot-id "$snap_id" --region "$AWS_REGION" || true
    #             fi
    #         done
    #     fi
        
    # else
    #     echo "No Frontend AMI ID found, skipping deregistration"
    # fi

    # if [ ! -z "$BACKEND_AMI_ID" ]; then
    #     echo "Deregistering Backend AMI: $BACKEND_AMI_ID"

    #     echo "Finding and deleting associated snapshots..."
    #     snapshot_ids=$(aws ec2 describe-images \
    #         --image-ids "$BACKEND_AMI_ID" \
    #         --region "$AWS_REGION" \
    #         --query "Images[0].BlockDeviceMappings[].Ebs.SnapshotId" \
    #         --output text 2>/dev/null)

    #     aws ec2 deregister-image --image-id $BACKEND_AMI_ID
    #     if [ -n "$snapshot_ids" ]; then
    #         for snap_id in $snapshot_ids; do
    #             if [ -n "$snap_id" ]; then
    #                 echo "Deleting snapshot: $snap_id"
    #                 aws ec2 delete-snapshot --snapshot-id "$snap_id" --region "$AWS_REGION" || true
    #             fi
    #         done
    #     fi
    # else
    #     echo "No Backend AMI ID found, skipping deregistration"
    # fi


  echo "Cleaning up AMIs"

  export AWS_REGION="us-east-1"

  declare -A AMI_FILES=(
    ["frontend"]="terraform/compute/modules/asg/ami_ids/frontend_ami.txt"
    ["backend"]="terraform/compute/modules/asg/ami_ids/backend_ami.txt"
  )

    # Loop over frontend and backend AMIs
    for component in frontend backend; do
      AMI_FILE="${AMI_FILES[$component]}"
      AMI_ID=""

      # Load AMI ID if file exists
      if [ -f "$AMI_FILE" ]; then
        AMI_ID=$(cat "$AMI_FILE")
      fi

      if [ -n "$AMI_ID" ]; then
        echo "🚀 Deregistering ${component^} AMI: $AMI_ID"

        echo "🔍 Finding and deleting associated snapshots..."
        snapshot_ids=$(aws ec2 describe-images \
          --image-ids "$AMI_ID" \
          --region "$AWS_REGION" \
          --query "Images[0].BlockDeviceMappings[].Ebs.SnapshotId" \
          --output text 2>/dev/null)

        aws ec2 deregister-image --image-id "$AMI_ID" --region "$AWS_REGION"

        if [ -n "$snapshot_ids" ]; then
          for snap_id in $snapshot_ids; do
            if [ -n "$snap_id" ]; then
              echo "🗑️  Deleting snapshot: $snap_id"
              aws ec2 delete-snapshot --snapshot-id "$snap_id" --region "$AWS_REGION" || true
            fi
          done
        fi
      else
        echo "⚠️  No ${component^} AMI ID found, skipping deregistration"
      fi
    done

    # # Clear AMI IDs folder if it exists
    if [ -d "terraform/compute/modules/asg/ami_ids" ]; then
        echo "Clearing AMI IDs folder"
        rm -f terraform/compute/modules/asg/ami_ids/*.txt
        # rm -f modules/asg/ami_ids/backend_ami.txt
    fi
    # Remove existing Packer manifest files if they exist
    if [[ -f "packer/backend/manifest.json" || -f "packer/frontend/manifest.json" ]]; then
        echo "🧹 Removing old Packer manifest files..."
        rm -f packer/backend/manifest.json 2>/dev/null || true
        rm -f packer/frontend/manifest.json 2>/dev/null || true
    else
        echo "ℹ️ No old Packer manifest files found."
    fi
) # subshell ended
# exit 1
# cd root
# Function to print section headers
print_section() {
    echo "================================================"
    echo " $1"
    echo "================================================"
}

# source env.sh
# terraform destroy -auto-approve -parallelism=20
# rm -f ../modules/asg/ami_ids/*
# exit 1
( # subshell started
    cd terraform

    # Path to the parent folder
    # parent_dir="terraform"
    # parent_dir=( "permissions" "network"  )
    parent_dir=("hosting" "compute" "database" "permissions" "network")
    print_line=("Destroying cloudfront, route53 modules"
                "Destroying alb, asg modules"
                "Destroying database, ssm_param modules"
                "Destroying iam_role, acm, key_pair modules"
                "Destroying VPC, security_group, s3 modules") 
    
    count=0
    # Loop through each folder inside the terraform directory
    # for folder in "$parent_dir"/*; do
    for folder in "${parent_dir[@]}"; do
        if [[ "$folder" == "hosting" || "$folder" == "compute" ]]; then
        # #   if [[ "$folder" == "network" || "$folder" == "permissions"  ]]; then
        # #     echo "The folder is network."
            count=$((count + 1))
            continue
        #     echo "destroying database"
        #     cd $folder
        #     terraform destroy  -auto-approve -parallelism=20
        #     exit 1

        fi
        if [ -d "$folder" ]; then
            # Start a subshell
            (
            echo "Performing operation in $folder"
            
            # Change into the folder
            cd "$folder" || exit
            
            # Print the line from the array
            print_section "${print_line[$count]}"
            # terraform force-unlock bc03bcab-9965-32d0-1232-325bd9d00a89

            terraform destroy -auto-approve -parallelism=20
            
            # Go back to the parent directory
            # cd - || exit # no need for this since i am running a subshell

            ) # Subshell exits, you are automatically back in $parent_dir
            # # Increment count
            count=$((count + 1))

            # # Check if we've exhausted the array
            if [ $count -ge ${#print_line[@]} ]; then
            echo "count greater than print_line array"
            break
            fi
        fi
    done
) # subshell started

#  Clean up S3 bucket
echo "Cleaning up S3 bucket"
# # Check if bucket exists
# BUCKET_NAME="panda-backend"
# if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
#     echo "Deleting S3 bucket: $BUCKET_NAME"
#     # first delete all the version of the objects in the bucket
#     aws s3api delete-objects \
#       --bucket $BUCKET_NAME \
#       --delete "$(aws s3api list-object-versions \
#       --bucket $BUCKET_NAME \
#       --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

    
#     aws s3api delete-objects \
#       --bucket $BUCKET_NAME \
#       --delete "$(aws s3api list-object-versions \
#       --bucket $BUCKET_NAME \
#       --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
#       --output json)"



#     # First, remove all objects in the bucket
#     aws s3 rm "s3://$BUCKET_NAME" --recursive || true
#     # Then delete the bucket
#     aws s3 rb "s3://$BUCKET_NAME" --force || true

  
# else
#     echo "S3 bucket $BUCKET_NAME does not exist, skipping deletion"
# fi

# # 7. Delete dynamodb table
echo "Cleaning up dyanmodb table"
# # Check if Tables exists
# TABLE_NAME="panda-lock-table"
# if aws dynamodb describe-table --table-name $TABLE_NAME 2>/dev/null ; then
#     echo "Deleting dyanmodb table: $TABLE_NAME"
#     aws dynamodb delete-table --table-name $TABLE_NAME
# else
#     echo "dyanmodb table $TABLE_NAME does not exist, skipping deletion"
# fi

(
    cd backend-tfstate-bootstrap
    terraform destroy -auto-approve
)
# cd ..
# Remove existing Packer manifest files if they exist
if [[ -f "packer/backend/manifest.json" || -f "packer/frontend/manifest.json" ]]; then
    echo "🧹 Removing old Packer manifest files..."
    rm -f packer/backend/manifest.json 2>/dev/null || true
    rm -f packer/frontend/manifest.json 2>/dev/null || true
else
    echo "ℹ️ No old Packer manifest files found."
fi

rm -f terraform/permissions/modules/key/*key*
rm -f terraform/permissions/modules/key/nat*
# rm -f terraform/compute/modules/asg/ami_ids/*


echo "Cleanup completed successfully!"


# ./startup.sh 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' > setup-logs/cleanupnew.log )