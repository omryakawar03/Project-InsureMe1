#AWS provider variables
variable "aws_region" {
    description = "region for aws_terraform"
    type        = string
    default     = "ap-south-1" # You can modify the region as needed
  
}
variable "profile_name" {
    description = "profile name for aws_terraform"
    type        = string
    default     = "eks-profile" # You can modify the profile name as needed
  
}


#eks cluster variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "Aws-eks-cluster" # You can modify the cluster name as needed
}
variable "instance_types" {
  description = "EC2 instance types for EKS node group"
  type        = list(string)
  default     = ["c7i-flex.large"] # You can modify the instance types as needed
}
variable "desired_size" {
  description = "Desired size for EKS node group"
  type        = number
  default     = 1    # Desired number of nodes in the node group
}
variable "max_size" {
  description = "Maximum size for EKS node group"
  type        = number
  default     = 2    # Maximum number of nodes in the node group
}
variable "min_size" {
  description = "Minimum size for EKS node group"
  type        = number
  default     = 1    # Minimum number of nodes in the node group
}
variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "Node_group_Cloud" # You can modify the node group name as needed
}
#backend s3 bucket name
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform backend"
  type        = string
  default     = "bucket-for-insureme-teraafrom-state-file" # Replace with your actual S3 bucket name make sure the bucket exists
}