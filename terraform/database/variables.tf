variable "region" {}
# variable "project_name" {}
variable "db_username" {}
variable "db_password" {}
variable "db_name" {}
variable "terraform_state_bucket" {}

# terragrunt input variables
variable "db_sg_id" {}
variable "pri_sub_7a_id" {}
variable "pri_sub_8b_id" {}
variable "project_name" {}

# grep -oP 'dependency\.\w+\.outputs\.\K\w+' terragrunt.hcl  | awk '{print "variable \"" $1 "\" {}"}' >> variables.tf
