variable "project_name"{}
# variable "ami" {
#     default = "ami-053b0d53c279acc90"
# }
variable "cpu" {
    # default = "t4g.micro"
    # https://aws.amazon.com/ec2/instance-types/t4/
    default = "t4g.small" # free tier till 31st dec/2025
}
# variable "key_name" {}
variable "client_sg_id" {}
variable "server_sg_id" {}
variable "max_size" {
    default = 1
}
variable "min_size" {
    default = 1
}
variable "desired_cap" {
    default = 1
}
variable "asg_health_check_type" {
    default = "ELB"
}
variable "vpc_id" {}
variable "vpc_cidr_block" {}
variable "pri_sub_3a_id" {}
variable "pri_sub_4b_id" {}
variable "pri_sub_5a_id" {}
variable "pri_sub_6b_id" {}
variable "tg_arn" {}
variable "internal_tg_arn" {}
# variable s3_ssm_instance_profile_name {}
variable s3_ssm_cw_instance_profile_name {}
variable db_dns_address {}
variable db_endpoint {}
variable db_username {}
variable db_password {}
variable db_name {}
# variable db_secret_name {}
variable internal_alb_dns_name {}
variable bucket_name {}
variable region {}
variable client_key_name {}
variable server_key_name {}
# variable frontend_ami_id {}
# variable backend_ami_id {}
variable pri_rt_a_id {}
variable pri_rt_b_id {}

variable "email_address" {
  type        = list(string)
  description = "List of email addresses to receive email alert"
  default     = ["ars786sh@gmail.com"]
}