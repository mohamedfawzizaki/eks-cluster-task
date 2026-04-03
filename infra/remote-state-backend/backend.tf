terraform {
  backend "s3" {
    # Leave these empty or generic; we will "inject" them during init
    bucket  = "" 
    key     = "zaki-terraform-remote-state/terraform.tfstate"
    region  = ""
    encrypt = true
  }
}
