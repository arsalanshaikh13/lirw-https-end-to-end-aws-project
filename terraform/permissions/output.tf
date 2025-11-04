output "s3_ssm_cw_role_name" {
  description = "IAM role name for S3 and SSM access"
  value       = module.iam_role.s3_ssm_cw_role_name
}
# output "s3_ssm_instance_profile_name" {
output "s3_ssm_cw_instance_profile_name" {
  description = "IAM role name for S3 and SSM access"
  value       = module.iam_role.s3_ssm_cw_instance_profile_name
}


output "client_key_name" {
  value = module.key.client_key_name
}
output "server_key_name" {
  value = module.key.server_key_name
}



output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = module.acm.certificate_arn
}

# Output the domain name
output "certificate_domain_name" {
  description = "ACM Certificate Domain Name"
  value       = module.acm.certificate_domain_name
}

# Output the certificate status
output "certificate_status" {
  description = "ACM Certificate Status"
  value       = module.acm.certificate_status
}