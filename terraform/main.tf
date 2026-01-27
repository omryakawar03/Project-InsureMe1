## IAM Role for EKS Cluster for assume role policy

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
# Create IAM Role for EKS Cluster with the assume role policy
resource "aws_iam_role" "cluster01" {
  name               = "eks-cluster-cloud"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach the AmazonEKSClusterPolicy to the IAM Role
resource "aws_iam_role_policy_attachment" "cluster01-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster01.name
}

#get vpc data
data "aws_vpc" "default" {
  default = true
}
#get public subnets for cluster
data "aws_subnets" "public" {
  filter {
    name   = "vpc-subnet-id"
    values = [data.aws_vpc.default.id]
  }
}
#cluster creation
resource "aws_eks_cluster" "cluster01" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster01.arn

  vpc_config {
    subnet_ids = data.aws_subnets.public.ids
  }

  #IAM Role policy attachment dependency Create before cluster creation
  depends_on = [
    aws_iam_role_policy_attachment.cluster01-AmazonEKSClusterPolicy,
  ]
}
# IAM Role for EKS Node Group
resource "aws_iam_role" "cluster_policy" {
  name = "eks-node-group-cloud"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}
# Attach required policies to the Node Group IAM Role
resource "aws_iam_role_policy_attachment" "cluster01-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.cluster_policy.name
}
 # Attach the AmazonEKS_CNI_Policy to the Node Group IAM Role
resource "aws_iam_role_policy_attachment" "cluster01-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.cluster_policy.name
}

resource "aws_iam_role_policy_attachment" "cluster01-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.cluster_policy.name
}

#create node group
resource "aws_eks_node_group" "cluster01" {
  cluster_name    = aws_eks_cluster.cluster01.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.cluster_policy.arn
  subnet_ids      = data.aws_subnets.public.ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }
  instance_types = var.instance_types

# IAM Role policy attachment dependency Create before node group creation and delete after node group deletion
  depends_on = [
    aws_iam_role_policy_attachment.cluster01-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.cluster01-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.cluster01-AmazonEC2ContainerRegistryReadOnly,
  ]
}