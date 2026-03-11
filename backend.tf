terraform {
  backend "s3" {
    bucket = "terraform-state-own-prod"
    key    = "infra/terraform.tfstate"
    region = "ap-northeast-1"
  }
}