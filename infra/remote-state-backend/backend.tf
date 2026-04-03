terraform {
  backend "s3" {
    bucket  = "727245885999-zaki-eks-task-tfstate"
    key     = "zaki-terraform-remote-state/terraform.tfstate"
    encrypt = true
    region  = "us-east-2"
  }
}