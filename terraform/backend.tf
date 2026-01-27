terraform {
  backend "s3" {
    bucket = var.s3_bucket_name 
    key    = "EKS/terraform.tfstate"
    region = "ap-south-1"
  }
}