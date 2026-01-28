terraform {
  backend "s3" {
    bucket = "aajchaprojecteksvr123hi"
    key    = "EKS/terraform.tfstate"
    region = "ap-south-1"
    profile = "eks-profile"
  }
}
