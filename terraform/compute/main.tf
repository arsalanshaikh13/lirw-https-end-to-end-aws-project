

# Creating Application Load balancer
module "alb" {
  source                  = "./modules/alb"
  project_name            = data.terraform_remote_state.network.outputs.project_name
  alb_sg_id               = data.terraform_remote_state.network.outputs.alb_sg_id
  internal_alb_sg_id      = data.terraform_remote_state.network.outputs.internal_alb_sg_id
  pub_sub_1a_id           = data.terraform_remote_state.network.outputs.pub_sub_1a_id
  pub_sub_2b_id           = data.terraform_remote_state.network.outputs.pub_sub_2b_id
  pri_sub_5a_id           = data.terraform_remote_state.network.outputs.pri_sub_5a_id
  pri_sub_6b_id           = data.terraform_remote_state.network.outputs.pri_sub_6b_id
  vpc_id                  = data.terraform_remote_state.network.outputs.vpc_id
  certificate_domain_name = var.certificate_domain_name

}

resource "null_resource" "build_ami" {
  depends_on = [module.alb]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      VPC_ID    = data.terraform_remote_state.network.outputs.vpc_id
      SUBNET_ID = data.terraform_remote_state.network.outputs.pub_sub_1a_id
      # Get RDS details from Terraform state
      DB_HOST                         = data.terraform_remote_state.database.outputs.endpoint_address
      DB_PORT                         = "3306"
      DB_USER                         = data.terraform_remote_state.database.outputs.db_username
      DB_PASSWORD                     = data.terraform_remote_state.database.outputs.db_password
      DB_NAME                         = data.terraform_remote_state.database.outputs.db_name
      RDS_SG_ID                       = data.terraform_remote_state.network.outputs.db_sg_id
      s3_ssm_cw_instance_profile_name = data.terraform_remote_state.permissions.outputs.s3_ssm_cw_instance_profile_name
      # db_secret_name                  = module.aws_secret.db_secret_name
      internal_alb_dns_name   = module.alb.internal_alb_dns_name
      bucket_name             = data.terraform_remote_state.network.outputs.lirw_bucket_name
      aws_region              = data.terraform_remote_state.network.outputs.region
      ANSIBLE_STDOUT_CALLBACK = "yaml"
    }
    # command = "bash ../../packer/packer-script.sh"
    # 👇 Run Ansible playbook instead of shell script
    # command = "ansible-playbook ../../packer/packer-ansible.yml -vv"
    # command = "ansible-playbook ../../packer/packer-ansible.yml -vvvv 2>&1 | tee -a ../../packer/ansible_output.log"
    # on_failure = fail

    # Add explicit error handling in the command
    # command = <<-EOT
    #   {
    #     set -euo pipefail  # Exit on any error
    #     ansible-playbook ../../packer/packer-ansible.yml -vvvv 2>&1 | tee -a ../../packer/ansible_output.log
    #     exit_code=$${PIPESTATUS[0]}
    #     if [ $$exit_code -ne 0 ]; then
    #       echo "❌ Ansible playbook failed with exit code $$exit_code"
    #       exit $$exit_code
    #     fi
    #     echo "✅ Ansible playbook completed successfully"      
    #   }
    # EOT
    command    = "chmod +x null_resource.sh && ./null_resource.sh"
    on_failure = fail
  }

  # # Optional: Add a destroy provisioner to clean up on failure
  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "echo 'Cleaning up failed AMI build resources...'"
  # }
}
#   triggers = {
# ensure re-run when packer template changes
# packer_template_hash = filesha256("../../packer/backend.pkr.hcl")
#   # Change any of these to force rebuild
#   server_build = filemd5("${path.module}/../packer/backend/build_ami.sh")
#   server_script = filemd5("${path.module}/../packer/backend/server.sh")
#   client_build = filemd5("${path.module}/../packer/frontend/build_ami.sh")
#   client_script = filemd5("${path.module}/../packer/frontend/client.sh")
#   # # Or manual trigger
#   # force_rebuild = var.backend_ami_version  # Change this value to rebuild
#   # force_rebuild = var.frontend_ami_version  # Change this value to rebuild
# }


# data "local_file" "packer_manifest_backend" {
#   filename   = "../packer/backend/manifest.json"
#   depends_on = [null_resource.build_ami]
# }

# data "local_file" "packer_manifest_frontend" {
#   filename   = "../packer/frontend/manifest.json"
#   depends_on = [null_resource.build_ami]
# }

# locals {
#   packer_manifest_backend = jsondecode(data.local_file.packer_manifest_backend.content)
#   packer_manifest_frontend = jsondecode(data.local_file.packer_manifest_frontend.content)

#   backend_ami_id  = split(":", local.packer_manifest_backend.builds[0].artifact_id)[1]
#   frontend_ami_id = split(":", local.packer_manifest_frontend.builds[0].artifact_id)[1]
# }


# locals {
#   packer_manifest_backend = jsondecode(file("../packer/backend/manifest.json"))
#   packer_manifest_frontend = jsondecode(file("../packer/frontend/manifest.json"))
#   backend_ami_id  = split(":", local.packer_manifest_backend.builds[0].artifact_id)[1]
#   frontend_ami_id  = split(":", local.packer_manifest_frontend.builds[0].artifact_id)[1]

#   depends_on = [null_resource.build_ami]
# }

# output "backend_ami_id" {
#   value = local.backend_ami_id
# }


module "asg" {
  source                          = "./modules/asg"
  project_name                    = data.terraform_remote_state.network.outputs.project_name
  client_sg_id                    = data.terraform_remote_state.network.outputs.client_sg_id
  server_sg_id                    = data.terraform_remote_state.network.outputs.server_sg_id
  vpc_id                          = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr_block                  = data.terraform_remote_state.network.outputs.vpc_cidr_block
  pri_sub_3a_id                   = data.terraform_remote_state.network.outputs.pri_sub_3a_id
  pri_sub_4b_id                   = data.terraform_remote_state.network.outputs.pri_sub_4b_id
  pri_sub_5a_id                   = data.terraform_remote_state.network.outputs.pri_sub_5a_id
  pri_sub_6b_id                   = data.terraform_remote_state.network.outputs.pri_sub_6b_id
  tg_arn                          = module.alb.tg_arn
  internal_tg_arn                 = module.alb.internal_tg_arn
  s3_ssm_cw_instance_profile_name = data.terraform_remote_state.permissions.outputs.s3_ssm_cw_instance_profile_name
  db_dns_address                  = data.terraform_remote_state.database.outputs.endpoint_address
  db_endpoint                     = data.terraform_remote_state.database.outputs.db_endpoint
  db_username                     = data.terraform_remote_state.database.outputs.db_username
  db_password                     = data.terraform_remote_state.database.outputs.db_password
  db_name                         = data.terraform_remote_state.database.outputs.db_name
  # db_secret_name                  = data.terraform_remote_state.database.outputs.db_secret_name
  internal_alb_dns_name = module.alb.internal_alb_dns_name
  bucket_name           = data.terraform_remote_state.network.outputs.lirw_bucket_name
  region                = data.terraform_remote_state.network.outputs.region
  # backend_ami_id  =  local.backend_ami_id
  # frontend_ami_id  = local.frontend_ami_id
  client_key_name = data.terraform_remote_state.permissions.outputs.client_key_name
  server_key_name = data.terraform_remote_state.permissions.outputs.server_key_name
  pri_rt_a_id     = data.terraform_remote_state.network.outputs.pri_rt_a_id
  pri_rt_b_id     = data.terraform_remote_state.network.outputs.pri_rt_b_id
  depends_on      = [module.alb, null_resource.build_ami]

}




