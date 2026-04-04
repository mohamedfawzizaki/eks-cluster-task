terraform {
  backend "s3" {
    bucket         = ""
    key            = "eks/cluster/terraform.tfstate"
    region         = ""
    encrypt        = true
    dynamodb_table = ""
  }
}