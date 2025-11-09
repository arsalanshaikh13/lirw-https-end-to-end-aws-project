include "root" {
  path   = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

include "global_mock" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true

}
locals {
  region = include.root.locals.region
  # original_dir = get_terragrunt_dir()
  original_dir = get_original_terragrunt_dir()
  frontend_ami_file = "${local.original_dir}/modules/asg/ami_ids/frontend_ami.txt"
  backend_ami_file  = "${local.original_dir}/modules/asg/ami_ids/backend_ami.txt"  
  packer_dir = "${get_repo_root()}/packer"
}

terraform {
  source = "./."

  # https://terragrunt.gruntwork.io/docs/features/hooks/
  before_hook "delete_AMI" {
    commands = ["destroy"]
    execute = [
      "bash", "-c",
      <<-EOT
      export frontend_ami_file="${local.frontend_ami_file}";
      export backend_ami_file="${local.backend_ami_file}";
      chmod +x "${get_original_terragrunt_dir()}/delete_AMI.sh";
      "${get_original_terragrunt_dir()}/delete_AMI.sh"
      EOT    
    ]
  }
  # https://developer.hashicorp.com/terraform/language/expressions/strings#indented-heredocs
  after_hook "delete_AMI_folder" {
    commands = ["destroy"]
    execute = [
      "bash", "-c",
      <<-EOT
      # # Clear AMI IDs folder if it exists
      if [ -d "${get_original_terragrunt_dir()}/modules/asg/ami_ids" ]; then
        echo "Clearing AMI IDs folder"
        rm -rf "${get_original_terragrunt_dir()}/modules/asg/ami_ids"
      fi
      EOT
    ]
  }

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

# Generate extended provider block (adds local & null)
generate "provider_compute" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
provider "aws" {
  region = "${local.region}"
}

EOF
}


dependency "network" {
  config_path                             = "../network"
  mock_outputs                            = include.global_mock.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "permissions" {
  config_path                             = "../permissions"
  mock_outputs                            = include.global_mock.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "database" {
  config_path                             = "../database"
  mock_outputs                            = include.global_mock.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}



inputs = {
  # frontend_ami_file = "${local.original_dir}/modules/asg/ami_ids/frontend_ami.txt"
  # backend_ami_file  = "${local.original_dir}/modules/asg/ami_ids/backend_ami.txt"  
  frontend_ami_file = local.frontend_ami_file
  backend_ami_file  = local.backend_ami_file
  packer_dir = "${local.packer_dir}"
  
  # module alb variables
  project_name       = dependency.network.outputs.project_name
  alb_sg_id          = dependency.network.outputs.alb_sg_id
  internal_alb_sg_id = dependency.network.outputs.internal_alb_sg_id
  pub_sub_1a_id      = dependency.network.outputs.pub_sub_1a_id
  pub_sub_2b_id      = dependency.network.outputsy
  .pub_sub_2b_id
  pri_sub_5a_id      = dependency.network.outputs.pri_sub_5a_id
  pri_sub_6b_id      = dependency.network.outputs.pri_sub_6b_id
  vpc_id             = dependency.network.outputs.vpc_id

  # null_resource variables
  # VPC_ID    = dependency.network.outputs.vpc_id
  vpc_id    = dependency.network.outputs.vpc_id
  # SUBNET_ID = dependency.network.outputs.pub_sub_1a_id
  pub_sub_1a_id = dependency.network.outputs.pub_sub_1a_id
  # Get RDS details from Terraform state
  endpoint_address                         = dependency.database.outputs.endpoint_address
  # DB_HOST                         = dependency.database.outputs.endpoint_address
  db_port                         = "3306"
  db_username                         = dependency.database.outputs.db_username
  # DB_USER                         = dependency.database.outputs.db_username
  # DB_PASSWORD                     = dependency.database.outputs.db_password
  db_password                     = dependency.database.outputs.db_password
  # DB_NAME                         = dependency.database.outputs.db_name
  db_name                         = dependency.database.outputs.db_name
  # RDS_SG_ID                       = dependency.network.outputs.db_sg_id
  db_sg_id                       = dependency.network.outputs.db_sg_id
  s3_ssm_cw_instance_profile_name = dependency.permissions.outputs.s3_ssm_cw_instance_profile_name
  # bucket_name                     = dependency.network.outputs.lirw_bucket_name
  lirw_bucket_name                     = dependency.network.outputs.lirw_bucket_name
  region                      = dependency.network.outputs.region

  # for mock purposes fetching mock alb dns
  # alb_dns_name                      = include.global_mock.locals.global_mock_outputs.alb_dns_name
  # internal_tg_arn                      = include.global_mock.locals.global_mock_outputs.internal_tg_arn
  # tg_arn                      = include.global_mock.locals.global_mock_outputs.tg_arn

  # modules asg variables
  client_sg_id   = dependency.network.outputs.client_sg_id
  server_sg_id   = dependency.network.outputs.server_sg_id
  vpc_cidr_block = dependency.network.outputs.vpc_cidr_block
  pri_sub_3a_id  = dependency.network.outputs.pri_sub_3a_id
  pri_sub_4b_id  = dependency.network.outputs.pri_sub_4b_id
  db_dns_address = dependency.database.outputs.endpoint_address
  db_endpoint    = dependency.database.outputs.db_endpoint
  db_username    = dependency.database.outputs.db_username
  db_password    = dependency.database.outputs.db_password
  db_name        = dependency.database.outputs.db_name
  # db_secret_name                  = dependency.database.outputs.db_secret_name
  region          = dependency.network.outputs.region
  client_key_name = dependency.permissions.outputs.client_key_name
  server_key_name = dependency.permissions.outputs.server_key_name
  pri_rt_a_id     = dependency.network.outputs.pri_rt_a_id
  pri_rt_b_id     = dependency.network.outputs.pri_rt_b_id

}



# before_hook "check_backend_exists" {
#   commands = ["apply", "plan"]
#   execute = [
#     "bash", "-c",
#     <<EOT
# BUCKET="terraform-state-lirw"
# if ! aws s3api head-bucket --bucket $BUCKET 2>/dev/null; then
#   echo "❌ Backend bucket $BUCKET not found!"
#   echo "👉 Run: terragrunt apply --terragrunt-working-dir backend-tfstate-bootstrap"
#   exit 1
# fi
# EOT
#   ]
# }
