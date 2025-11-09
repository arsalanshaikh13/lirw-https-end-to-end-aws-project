variable "terraform_state_bucket" {}
variable "region" {}

# terragrunt input variables
variable "vpc_id" {}
# variable "region" {}

# grep -oP 'dependency\.\w+\.outputs\.\K\w+' terragrunt.hcl  | awk '{print "variable \"" $1 "\" {}"}' >> variables.tf