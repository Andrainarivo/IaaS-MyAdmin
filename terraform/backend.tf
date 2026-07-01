# ./terraform/backend.tf

terraform {
  backend "gcs" {
    bucket = "myadmin-tfstate-myadminproject-501004"
    prefix = "terraform/state"
  }
}