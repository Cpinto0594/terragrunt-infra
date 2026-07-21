locals {

  kube_cluster_name = var.kube_cluster_name

}

data "aws_eks_cluster" "eks_cluster" {
  name = local.kube_cluster_name
}

data "aws_eks_node_groups" "eks_cluster_node_groups" {
  cluster_name = local.kube_cluster_name
}

data "aws_eks_cluster_auth" "aws_eks_cluster" {
  name = try(local.kube_cluster_name, data.aws_eks_cluster.eks_cluster.id)
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.aws_eks_cluster.token
}

provider "helm" {
  debug = true
  kubernetes = {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.aws_eks_cluster.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.aws_eks_cluster.token

}
