
output "region" {
  value = var.region
}

output "project_name" {
  value = var.project_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "pub_sub_1a_id" {
  value = module.vpc.pub_sub_1a_id
}
output "pub_sub_2b_id" {
  value = module.vpc.pub_sub_2b_id
}
output "pri_sub_3a_id" {
  value = module.vpc.pri_sub_3a_id
}

output "pri_sub_4b_id" {
  value = module.vpc.pri_sub_4b_id
}

output "pri_sub_5a_id" {
  value = module.vpc.pri_sub_5a_id
}

output "pri_sub_6b_id" {
  value = module.vpc.pri_sub_6b_id
}
output "pri_sub_7a_id" {
  value = module.vpc.pri_sub_7a_id
}
output "pri_sub_8b_id" {
  value = module.vpc.pri_sub_8b_id
}
output "pri_rt_a_id" {
  value = module.vpc.pri_rt_a_id
}
output "pri_rt_b_id" {
  value = module.vpc.pri_rt_b_id
}
output "igw_id" {
  value = module.vpc.igw_id
}

output "lirw_bucket_name" {
  value = module.s3.lirw_bucket_name
}


output "alb_sg_id" {
  value = module.security-group.alb_sg_id
}

output "client_sg_id" {
  value = module.security-group.client_sg_id
}

output "internal_alb_sg_id" {
  value = module.security-group.internal_alb_sg_id
}

output "server_sg_id" {
  value = module.security-group.server_sg_id
}

output "db_sg_id" {
  value = module.security-group.db_sg_id
}
output debug_files {
  value = module.s3.debug_files
}