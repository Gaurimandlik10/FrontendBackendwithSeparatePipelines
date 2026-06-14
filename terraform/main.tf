terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    bucket = "proj2-terraformstatebucket-500345929326-ap-southeast-2-an"
    key    = "restnodejs/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

resource "aws_vpc" "proj3_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "proj3" }
}

resource "aws_subnet" "proj3_subnet_1" {
  vpc_id                  = aws_vpc.proj3_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = { Name = "proj3_subnet_1" }
}

resource "aws_subnet" "proj3_subnet_2" {
  vpc_id                  = aws_vpc.proj3_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = true
  tags = { Name = "proj3_subnet_2" }
}

resource "aws_internet_gateway" "proj3_igw" {
  vpc_id = aws_vpc.proj3_vpc.id
  tags   = { Name = "proj3_igw" }
}

resource "aws_route_table" "proj3_rt" {
  vpc_id = aws_vpc.proj3_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proj3_igw.id
  }
  tags = { Name = "proj3_rt" }
}

resource "aws_route_table_association" "proj3_rta_1" {
  subnet_id      = aws_subnet.proj3_subnet_1.id
  route_table_id = aws_route_table.proj3_rt.id
}

resource "aws_route_table_association" "proj3_rta_2" {
  subnet_id      = aws_subnet.proj3_subnet_2.id
  route_table_id = aws_route_table.proj3_rt.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "proj3_cluster"
  cluster_version = "1.32"

  vpc_id     = aws_vpc.proj3_vpc.id
  subnet_ids = [
    aws_subnet.proj3_subnet_1.id,
    aws_subnet.proj3_subnet_2.id
  ]

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["c7i-flex.large"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      ami_type       = "AL2023_x86_64_STANDARD"
      tags           = { Name = "eks-worker-nodes" }
    }
  }
}
resource "kubernetes_namespace" "proj3_namespace" {
  metadata {
    name = "proj3-namespace"
  }

  depends_on = [module.eks]
}