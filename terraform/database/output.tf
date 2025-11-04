# output "db_secret_id" {
#     value = module.aws_ssm_param.db_secret_id
# }
# output "db_secret_name" {
#     value = module.aws_ssm_param.db_secret_name
# }

output "endpoint_address" {
  description = "dns address for db instance endpoint"
  value       = module.rds.endpoint_address
}

output "db_endpoint" {
  description = "db instance  endpoint for db instance"
  value       = module.rds.db_endpoint
}
output "db_name" {
  description = "db instance  name for db instance"
  value       = var.db_name
}
output "db_username" {
  description = "db instance  username for db instance"
  value       = module.rds.db_username
}
output "db_password" {
  description = "db instance  password for db instance"
  value       = module.rds.db_password
  sensitive   = true
}