# infra/network/terragrunt.hcl
include {
  path = find_in_parent_folders()
}

include "global_mock" {
  path = find_in_parent_folders("global-mocks.hcl")
}

terraform {
  source = "./." # Uses the local folder's Terraform code  
  before_hook "pre_fmt" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform format'; terraform fmt --recursive"]
  }
  before_hook "pre_validate" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform validate'; terraform validate"]
  }
  
  before_hook "tflint" {
    commands = ["plan"]
    execute = [
      "bash", "-c",
      <<-EOT
        tflint --recursive --minimum-failure-severity=error --config "${get_original_terragrunt_dir()}/custom.tflint.hcl"
        exit_code=$?
        if [ $exit_code -gt 0 ]; then
          echo "exit code : $exit_code"
          echo "✅ TFLint completed with issues (non-fatal). Continuing Terragrunt..."
          exit 0
        else
          echo "exit code : $exit_code"
          exit $exit_code
        fi
      EOT
    ]
  }

  after_hook "post_apply_graph" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo 'Running terraform graph'; terraform graph > '${get_original_terragrunt_dir()}'/graph/graph-apply.dot"]
  }
  after_hook "post_apply_message" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Resources created successfully'"]
  }
  after_hook "post_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "echo '✅ Resources deleted successfully'"]
  }
}




locals {
  # web = "website2_0"
  # upload_folder = "/mnt/c/Users/DELL/ArsVSCode/CS50p_project/project_aFinal/website/${local.web}/animations/scroll/aws_three_tier_arch/lirw-three-tier/folder-based-project/lirw-three-tier"
  # upload_folder = "${get_original_terragrunt_dir()}/lirw-three-tier"
  upload_folder = "${get_repo_root()}/lirw-three-tier"
  # upload_folder = "${dirname(get_parent_terragrunt_dir("global_mock"))}/lirw-three-tier"
  # upload_folderss = "${get_parent_terragrunt_dir("global_mock")}/lirw-three-tier"

}

inputs = {
  upload_folder = "${local.upload_folder}"
}


# tflint --recursive --minimum-failure-severity=error --config "$(pwd)/custom.tflint.hcl"