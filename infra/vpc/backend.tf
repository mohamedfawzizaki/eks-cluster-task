terraform {
  backend "s3" {
    bucket         = ""
    key            = "vpc/terraform.tfstate"
    region         = ""
    encrypt        = true
    dynamodb_table = ""
  }
}