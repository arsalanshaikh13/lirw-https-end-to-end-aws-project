# infra/terragrunt.hcl
locals {
  region         = "us-east-1"
  project_name   = "lirw-three-tier"
  bucket_name    = "terraform-state-lirw-backend"
  dynamodb_table = "terraform-lock-lirw-table"
  # # global_mocks
  # global_mock_outputs = {
  #   additional_domain_name          = "extra.example.com"
  #   alb_api_domain_name             = "api.example.com"
  #   alb_dns_name                    = "internal-alb-123456789.us-east-1.elb.amazonaws.com"
  #   alb_domain_name                 = "app.example.com"
  #   alb_sg_id                       = "sg-0a1b2c3d4e5f6g7h8"
  #   alb_waf_name                    = "mock-waf-web-acl"
  #   alb_zone_id                     = "Z123MOCKZONEID"
  #   ami                             = "ami-0123456789abcdef0"
  #   asg_health_check_type           = "EC2"
  #   aws_region                      = "us-east-1"
  #   bucket_name                     = "mock-terraform-bucket"
  #   certificate_domain_name         = "cert.example.com"
  #   client_key_name                 = "mock-client-key"
  #   client_sg_id                    = "sg-1234abcd5678efgh9"
  #   cloudfront_header_name          = "X-Mock-Header"
  #   cloudfront_header_value         = "mock-header-value"
  #   cpu                             = "2"
  #   db_endpoint                     = "mock-db-instance.abcdefghijkl.us-east-1.rds.amazonaws.com"
  #   db_name                         = "mockdb"
  #   db_password                     = "MockDBPassword123!"
  #   db_secret_name                  = "mock-db-secret"
  #   db_sg_id                        = "sg-db1234567890abcd"
  #   db_sub_name                     = "mock-db-subnet-group"
  #   db_username                     = "mockuser"
  #   desired_cap                     = "2"
  #   email_address                   = "admin@example.com"
  #   endpoint_address                = "mock-endpoint.example.com"
  #   internal_alb_sg_id              = "sg-internalalb1234abcd"
  #   internal_tg_arn                 = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/internal-tg/mock123"
  #   key_name                        = "mock-ssh-key"
  #   lirw_bucket_name                = "mock-lirw-bucket"
  #   max_size                        = "5"
  #   min_size                        = "1"
  #   pri_rt_a_id                     = "rtb-1234abcd5678efgh9"
  #   pri_rt_b_id                     = "rtb-9876zyxw5432vuts"
  #   pri_sub_3a_cidr                 = "10.0.3.0/24"
  #   pri_sub_3a_id                   = "subnet-3a1234abcd5678ef"
  #   pri_sub_4b_cidr                 = "10.0.4.0/24"
  #   pri_sub_4b_id                   = "subnet-4b9876zyxw5432vu"
  #   pri_sub_5a_cidr                 = "10.0.5.0/24"
  #   pri_sub_5a_id                   = "subnet-5a1111aaaa2222bbb"
  #   pri_sub_6b_cidr                 = "10.0.6.0/24"
  #   pri_sub_6b_id                   = "subnet-6b3333cccc4444ddd"
  #   pri_sub_7a_cidr                 = "10.0.7.0/24"
  #   pri_sub_7a_id                   = "subnet-7a5555eeee6666fff"
  #   pri_sub_8b_cidr                 = "10.0.8.0/24"
  #   pri_sub_8b_id                   = "subnet-8b7777gggg8888hhh"
  #   project_name                    = "mock-project"
  #   pub_sub_1a_cidr                 = "10.0.1.0/24"
  #   pub_sub_1a_id                   = "subnet-1aabcd1234efgh567"
  #   pub_sub_2b_cidr                 = "10.0.2.0/24"
  #   pub_sub_2b_id                   = "subnet-2babcd9876efgh543"
  #   public_alb_arn                  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/public-alb/mock123"
  #   region                          = "us-east-1"
  #   s3_ssm_cw_instance_profile_name = "mock-ec2-instance-profile"
  #   server_key_name                 = "mock-server-key"
  #   server_sg_id                    = "sg-server1234abcd5678"
  #   terraform_state_bucket          = "mock-tfstate-bucket"
  #   tg_arn                          = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/mock-tg/abc123def456"
  #   vpc_cidr                        = "10.0.0.0/16"
  #   vpc_cidr_block                  = "10.0.0.0/16"
  #   vpc_id                          = "vpc-0a1b2c3d4e5f6g7h8"
  # }
}

remote_state {
  backend = "s3"
  config = {
    bucket         = local.bucket_name
    key            = "${path_relative_to_include()}/lirw-app.tfstate"
    region         = local.region
    dynamodb_table = local.dynamodb_table
    encrypt        = true
    use_lockfile   = true
  }
}

# Automatically generate provider.tf for all subfolders
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  region = "${local.region}"
}
EOF
}

# terraform {

#   before_hook "check_backend_exists" {
#     commands = ["apply", "plan"]

#   #   # https://developer.hashicorp.com/terraform/language/expressions/strings#indented-heredocs
#   #   # execute = [
#   #   #   "bash", "-c",
#   #   #   "BUCKET='terraform-state-lirw'; \
#   #   #   if ! aws s3api head-bucket --bucket $BUCKET 2>/dev/null; then \
#   #   #     echo '❌ Backend bucket $BUCKET not found!'; \
#   #   #     echo '👉 Run: terragrunt apply --terragrunt-working-dir backend-tfstate-bootstrap'; \
#   #   #     exit 1; \
#   #   #   fi"
#   #   # ]

#     execute = [
#       "bash", "-c",
#       <<-EOT
#         echo "🔍 Checking backend state..."
#         if [[ -d ./backend-tfstate-bootstrap/.terraform && 
#               -f ./backend-tfstate-bootstrap/.terraform.lock.hcl && 
#               -f ./backend-tfstate-bootstrap/terraform.tfstate && 
#               $(jq '.resources | length' ./backend-tfstate-bootstrap/terraform.tfstate) -gt 0 ]]; then
#           echo " Backend already bootstrapped — skipping hook logic."
#           exit 0
#         else
#           echo '❌ Backend bucket $BUCKET not found!'
#           echo " Bootstrapping backend..."
#           # terragrunt apply --terragrunt-working-dir backend-tfstate-bootstrap --terragrunt-non-interactive; 
#           exit 0
#         fi
#       EOT
#     ]
#   }
# }



