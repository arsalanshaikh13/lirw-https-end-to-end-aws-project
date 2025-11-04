data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "network/lirw-app.tfstate"
    region = "us-east-1"

  }
}

data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "compute/lirw-app.tfstate"
    region = "us-east-1"

  }
}