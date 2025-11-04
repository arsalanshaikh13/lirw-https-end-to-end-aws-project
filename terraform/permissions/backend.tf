terraform {
  backend "s3" {
    bucket         = "lirw-backend"
    key            = "permissions/lirw-app.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lirw-lock-table"
    use_lockfile   = true
  }
}