terraform {
  backend "s3" {
    bucket         = ""
    key            = "iam/eks/cluster-access/terraform.tfstate"
    region         = ""
    encrypt        = true
    dynamodb_table = ""
  }
}
