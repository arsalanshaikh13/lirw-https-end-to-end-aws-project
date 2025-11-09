
variable "certificate_domain_name" {}
variable "additional_domain_name" {}
variable "alb_api_domain_name" {}
variable "region" {}
variable "terraform_state_bucket" {}

# terragrunt input variables
variable "project_name" {}
variable "public_alb_arn" {}
variable "alb_dns_name" {}
variable "alb_zone_id" {}

# grep -oP 'dependency\.\w+\.outputs\.\K\w+' terragrunt.hcl  | awk '{print "variable \"" $1 "\" {}"}' >> variables.tf