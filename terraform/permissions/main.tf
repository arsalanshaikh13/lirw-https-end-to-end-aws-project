
module "iam_role" {
  source = "./modules/iam_role"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  region = data.terraform_remote_state.network.outputs.region
}



# module "nat_instance" {
#   source = "./modules/nat_instance"

#   pub_sub_1a_id  = data.terraform_remote_state.network.outputs.pub_sub_1a_id
#   pub_sub_2b_id  = data.terraform_remote_state.network.outputs.pub_sub_2b_id
#   pri_sub_3a_id  = data.terraform_remote_state.network.outputs.pri_sub_3a_id
#   pri_sub_4b_id  = data.terraform_remote_state.network.outputs.pri_sub_4b_id
#   pri_sub_5a_id  = data.terraform_remote_state.network.outputs.pri_sub_5a_id
#   pri_sub_6b_id  = data.terraform_remote_state.network.outputs.pri_sub_6b_id
#   igw_id         = data.terraform_remote_state.network.outputs.igw_id
#   vpc_id         = data.terraform_remote_state.network.outputs.vpc_id
#   vpc_cidr_block = data.terraform_remote_state.network.outputs.vpc_cidr_block
#   s3_ssm_cw_instance_profile_name = module.iam_role.s3_ssm_cw_instance_profile_name
#   nat_bastion_key_name =  module.key.nat_bastion_key_name
# pri_rt_a_id = data.terraform_remote_state.network.outputs.pri_rt_a_id
# pri_rt_b_id = data.terraform_remote_state.network.outputs.pri_rt_b_id

#   depends_on                      = [ module.iam_role] # Wait for VPC before DB
# }

module "acm" {
  source = "./modules/acm"
}



# creating Key for instances
module "key" {
  source = "./modules/key"
}

