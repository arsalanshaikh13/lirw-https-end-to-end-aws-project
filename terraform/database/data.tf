data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "network/lirw-app.tfstate"
    region = var.region
  }
}
data "terraform_remote_state" "permissions" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "permissions/lirw-app.tfstate"
    region = var.region
  }
}