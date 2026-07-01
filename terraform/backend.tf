# ./terraform/backend.tf

terraform {
  backend "gcs" {
    bucket = "myadmin-tfstate-myadminproject"
    prefix = "terraform/state"
  }
}