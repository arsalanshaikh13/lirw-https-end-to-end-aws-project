# https://github.com/piyushsachdeva/10WeeksOfCloudOps_Task3/blob/main/modules/asg/main.tf
# piyush sachdeva  - https://www.youtube.com/watch?v=s8q5B6DLH7s&list=PLl4APkPHzsUUc8HOEIwfB3Z2uxRv2SKOG&index=5

# https://github.com/ajitinamdar-tech/three-tier-architecture-aws-terraform/blob/main/setup.sh
# ajit inamdar - https://www.youtube.com/watch?v=zHAG2GRQB7c&list=PL8HtOZJl_UXLHXvul8kFcvqVkOtnXPCZC&index=21

# https://github.com/harishnshetty/3-tier-aws-terraform-packer-statelock-project/blob/main/terraform/compute/app_user_data.sh
# harishnshetty - https://www.youtube.com/watch?v=M6BxKpSvWa4
# https://github.com/harishnshetty/3-tier-aws-15-services
# harishnshetty : How to Create a Scalable 3 Tier AWS Project | Secret Manager, Route53, & High Availability +15 Srv - https://www.youtube.com/watch?v=wPrktKBkBQk&t=2s

# https://www.youtube.com/watch?v=pdwGsM2MmDU&t=1s - Securing a ALB with CloudFront, Enabling HTTPS, SSL Termination & Restricting Direct Access to a ALB
# Hands-On With Digital Den

# https://www.youtube.com/watch?v=6rsJlfpwnP4&list=PLcWsizQR0OZAX5pMLiEkzHpLUetKzKYFY&index=6 - Deploy a Production-Grade 3-Tier Architecture on AWS | CloudFront, ALB, ASG, EC2, RDS, CloudWatch
#Learn It Right Way
# https://github.com/Learn-It-Right-Way/lirw-react-node-mysql-app/tree/feature/add-logging

module "vpc" {
  source          = "../modules/vpc"
  region          = var.region
  project_name    = var.project_name
  vpc_cidr        = var.vpc_cidr
  pub_sub_1a_cidr = var.pub_sub_1a_cidr
  pub_sub_2b_cidr = var.pub_sub_2b_cidr
  pri_sub_3a_cidr = var.pri_sub_3a_cidr
  pri_sub_4b_cidr = var.pri_sub_4b_cidr
  pri_sub_5a_cidr = var.pri_sub_5a_cidr
  pri_sub_6b_cidr = var.pri_sub_6b_cidr
  pri_sub_7a_cidr = var.pri_sub_7a_cidr
  pri_sub_8b_cidr = var.pri_sub_8b_cidr
}

module "iam_role" {
  source     = "../modules/iam_role"
  vpc_id     = module.vpc.vpc_id
  depends_on = [module.vpc]
}


module "security-group" {
  source     = "../modules/security-group"
  vpc_id     = module.vpc.vpc_id
  depends_on = [module.vpc] # Wait for VPC before DB
}

# module "nat" {
#   source = "../modules/nat"

#   pub_sub_1a_id = module.vpc.pub_sub_1a_id
#   igw_id        = module.vpc.igw_id
#   pub_sub_2b_id = module.vpc.pub_sub_2b_id
#   vpc_id        = module.vpc.vpc_id
#   pri_sub_3a_id = module.vpc.pri_sub_3a_id
#   pri_sub_4b_id = module.vpc.pri_sub_4b_id
#   pri_sub_5a_id = module.vpc.pri_sub_5a_id
#   pri_sub_6b_id = module.vpc.pri_sub_6b_id
  # pri_rt_a_id = module.vpc.pri_rt_a_id
  # pri_rt_b_id = module.vpc.pri_rt_b_id

# }


# module "nat_instance" {
#   source = "../modules/nat_instance"

#   pub_sub_1a_id  = module.vpc.pub_sub_1a_id
#   pub_sub_2b_id  = module.vpc.pub_sub_2b_id
#   pri_sub_3a_id  = module.vpc.pri_sub_3a_id
#   pri_sub_4b_id  = module.vpc.pri_sub_4b_id
#   pri_sub_5a_id  = module.vpc.pri_sub_5a_id
#   pri_sub_6b_id  = module.vpc.pri_sub_6b_id
#   igw_id         = module.vpc.igw_id
#   vpc_id         = module.vpc.vpc_id
#   vpc_cidr_block = module.vpc.vpc_cidr_block
#   # s3_ssm_instance_profile_name = module.iam_role.s3_ssm_instance_profile_name
#   s3_ssm_cw_instance_profile_name = module.iam_role.s3_ssm_cw_instance_profile_name
#   nat_bastion_key_name =  module.key.nat_bastion_key_name
  # pri_rt_a_id = module.vpc.pri_rt_a_id
  # pri_rt_b_id = module.vpc.pri_rt_b_id

#   depends_on                      = [module.vpc, module.iam_role] # Wait for VPC before DB
# }

# creating s3 bucket to keep application files
module "s3" {
  source      = "../modules/s3"
  bucket_name = var.bucket_name
}
module "acm" {
  source = "../modules/acm"
}

# creating RDS instance
module "rds" {
  source        = "../modules/rds"
  db_sg_id      = module.security-group.db_sg_id
  pri_sub_7a_id = module.vpc.pri_sub_7a_id
  pri_sub_8b_id = module.vpc.pri_sub_8b_id
  db_username   = var.db_username
  db_password   = var.db_password
  depends_on    = [module.vpc, module.security-group] # Wait for VPC before DB
}

module "aws_ssm_param" {
  source         = "../modules/aws_ssm_param"
  db_dns_address = module.rds.endpoint_address
  db_username    = var.db_username
  db_password    = var.db_password
  db_name        = var.db_name
  project_name   = module.vpc.project_name
  depends_on     = [module.rds] # Wait for VPC before DB

}


# creating Key for instances
module "key" {
  source = "../modules/key"
}

# Creating Application Load balancer
module "alb" {
  source                  = "../modules/alb"
  project_name            = module.vpc.project_name
  alb_sg_id               = module.security-group.alb_sg_id
  internal_alb_sg_id      = module.security-group.internal_alb_sg_id
  pub_sub_1a_id           = module.vpc.pub_sub_1a_id
  pub_sub_2b_id           = module.vpc.pub_sub_2b_id
  pri_sub_5a_id           = module.vpc.pri_sub_5a_id
  pri_sub_6b_id           = module.vpc.pri_sub_6b_id
  vpc_id                  = module.vpc.vpc_id
  certificate_domain_name = var.certificate_domain_name
  depends_on              = [module.vpc, module.security-group, module.acm] # Wait for VPC before DB

}

resource "null_resource" "build_ami" {
  depends_on = [module.vpc, module.security-group, module.aws_ssm_param, module.iam_role, module.rds, module.alb]

  provisioner "local-exec" {
    environment = {
      VPC_ID    = module.vpc.vpc_id
      SUBNET_ID = module.vpc.pub_sub_1a_id
      # Get RDS details from Terraform state
      DB_HOST                         = module.rds.endpoint_address
      DB_PORT                         = "3306"
      DB_USER                         = var.db_username
      DB_PASSWORD                     = var.db_password
      DB_NAME                         = var.db_name
      RDS_SG_ID                       = module.security-group.db_sg_id
      s3_ssm_cw_instance_profile_name = module.iam_role.s3_ssm_cw_instance_profile_name
      # db_secret_name                  = module.aws_secret.db_secret_name
      internal_alb_dns_name = module.alb.internal_alb_dns_name
      bucket_name           = module.s3.lirw_bucket_name
      aws_region            = var.region

    }
    command = "bash ../packer/packer-script.sh"
  }
  #   triggers = {
  #   # Change any of these to force rebuild
  #   server_build = filemd5("${path.module}/../packer/backend/build_ami.sh")
  #   server_script = filemd5("${path.module}/../packer/backend/server.sh")
  #   client_build = filemd5("${path.module}/../packer/frontend/build_ami.sh")
  #   client_script = filemd5("${path.module}/../packer/frontend/client.sh")
  #   # # Or manual trigger
  #   # force_rebuild = var.backend_ami_version  # Change this value to rebuild
  #   # force_rebuild = var.frontend_ami_version  # Change this value to rebuild
  # }
}

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
  source          = "../modules/asg"
  project_name    = module.vpc.project_name
  client_sg_id    = module.security-group.client_sg_id
  server_sg_id    = module.security-group.server_sg_id
  vpc_id          = module.vpc.vpc_id
  vpc_cidr_block  = module.vpc.vpc_cidr_block
  pri_sub_3a_id   = module.vpc.pri_sub_3a_id
  pri_sub_4b_id   = module.vpc.pri_sub_4b_id
  pri_sub_5a_id   = module.vpc.pri_sub_5a_id
  pri_sub_6b_id   = module.vpc.pri_sub_6b_id
  tg_arn          = module.alb.tg_arn
  internal_tg_arn = module.alb.internal_tg_arn
  # s3_ssm_instance_profile_name = module.iam_role.s3_ssm_instance_profile_name
  s3_ssm_cw_instance_profile_name = module.iam_role.s3_ssm_cw_instance_profile_name
  db_dns_address                  = module.rds.endpoint_address
  db_endpoint                     = module.rds.db_endpoint
  db_username                     = var.db_username
  db_password                     = var.db_password
  db_name                         = var.db_name
  # db_secret_name                  = module.aws_secret.db_secret_name
  internal_alb_dns_name = module.alb.internal_alb_dns_name
  bucket_name           = module.s3.lirw_bucket_name
  region                = var.region
  # backend_ami_id  =  local.backend_ami_id
  # frontend_ami_id  = local.frontend_ami_id
  client_key_name = module.key.client_key_name
  server_key_name = module.key.server_key_name
  pri_rt_a_id = module.vpc.pri_rt_a_id
  pri_rt_b_id = module.vpc.pri_rt_b_id
  depends_on      = [module.alb, module.iam_role, module.s3, module.rds, null_resource.build_ami] # Wait for VPC before DB

}




# create cloudfront distribution 
module "cloudfront" {
  source = "../modules/cloudfront"
  # certificate_domain_name = module.route53.acm_domain_name
  certificate_domain_name = var.certificate_domain_name
  # alb_domain_name         = module.alb.alb_dns_name
  alb_api_domain_name    = var.alb_api_domain_name
  additional_domain_name = var.additional_domain_name
  project_name           = module.vpc.project_name
  public_alb_arn         = module.alb.public_alb_arn
  depends_on             = [module.alb, module.asg] # Wait for VPC before DB

}


# Add record in route 53 hosted zone

module "route53" {
  source                    = "../modules/route53"
  cloudfront_domain_name    = module.cloudfront.cloudfront_domain_name
  cloudfront_distro_aliases = module.cloudfront.cloudfront_aliases
  cloudfront_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  public_alb_dns_name       = module.alb.alb_dns_name
  public_alb_zone_id        = module.alb.alb_zone_id

  depends_on = [module.alb] # Wait for VPC before DB

}


