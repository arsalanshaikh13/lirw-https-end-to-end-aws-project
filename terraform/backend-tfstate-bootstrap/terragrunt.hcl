# backend-tfstate-bootstrap/terragrunt.hcl
terraform {
  source = "./"

  # Run automatically before any other folder


  before_hook "pre_plan" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo '✅ Terraform backend bucket and DynamoDB planned successfully'"]
  }
  before_hook "pre_apply" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Terraform backend bucket and DynamoDB is being created'"]
  }
  after_hook "post_apply" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Terraform backend bucket and DynamoDB is created successfully '"]
  }
  after_hook "post_backend_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "echo '✅ Terraform backend bucket and DynamoDB deleted successfully'"]
  }

}

inputs = {
  bucket_name    = "terraform-state-lirw-backend"
  dynamodb_table = "terraform-lock-lirw-table"
  aws_region     = "us-east-1"
}

# terragrunt run --all --experiment-mode --filter '!backend-tfstate-bootstrap' -- plan