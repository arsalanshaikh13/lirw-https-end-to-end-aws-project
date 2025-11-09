variable "certificate_domain_name" {}
variable "terraform_state_bucket" {}

# terragrunt input variables
variable "project_name" {}
variable "alb_sg_id" {}
variable "internal_alb_sg_id" {}
variable "pub_sub_1a_id" {}
variable "pub_sub_2b_id" {}
variable "pri_sub_5a_id" {}
variable "pri_sub_6b_id" {}
variable "vpc_id" {}
# variable "vpc_id" {}
# variable "pub_sub_1a_id" {}
variable "endpoint_address" {}
variable "db_username" {}
variable "db_password" {}
variable "db_name" {}
variable "db_port" {}
variable "db_sg_id" {}
variable "s3_ssm_cw_instance_profile_name" {}
variable "lirw_bucket_name" {}
# variable "region" {}
variable "client_sg_id" {}
variable "server_sg_id" {}
variable "vpc_cidr_block" {}
variable "pri_sub_3a_id" {}
variable "pri_sub_4b_id" {}
# variable "endpoint_address" {}
variable "db_endpoint" {}
# variable "db_username" {}
# variable "db_password" {}
# variable "db_name" {}
# variable "db_secret_name" {}
variable "region" {}
variable "client_key_name" {}
variable "server_key_name" {}
variable "pri_rt_a_id" {}
variable "pri_rt_b_id" {}


variable "backend_ami_file" {}
variable "frontend_ami_file" {}
variable "packer_dir" {}

# for mock purposes fetching mock alb dns name
# variable "alb_dns_name" {}
# variable "internal_tg_arn" {}
# variable "tg_arn" {}

# grep -oP 'dependency\.\w+\.outputs\.\K\w+' terragrunt.hcl  | awk '{print "variable \"" $1 "\" {}"}' >> variables.tf
# awk '/inputs\s*=\s*{/,/}/' terragrunt.hcl | grep -oP '^\s*\K\w+(?=\s*=)' | awk '{print "variable \"" $1 "\" {}"}' >> variables.tf

