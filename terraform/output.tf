output "aws_vpc_id" {
  value = aws_vpc.proj3_vpc.id
}

output "aws_subnet_1_id" {
  value = aws_subnet.proj3_subnet_1.id
}

output "aws_subnet_2_id" {
  value = aws_subnet.proj3_subnet_2.id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "namespace" {
  value = kubernetes_namespace.proj3_namespace.metadata[0].name
}