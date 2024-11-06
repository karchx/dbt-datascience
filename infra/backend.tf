terraform {
  backend "s3" {
    bucket = "iac-tfstate-demo"
    key    = "worksapce/test/terraform.tfstate"
    region = "us-east-1"
  }
}
