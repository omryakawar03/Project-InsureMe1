terraform {
  backend "s3" {
    bucket = "<YOUR_S3_BUCKET_NAME>"
    key    = "EKS/terraform.tfstate"
    region = "ap-south-1"
    profile = "eks-profile"
  }
}
