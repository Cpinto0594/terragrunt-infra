data "aws_eks_clusters" "clusters" {}

data "aws_eks_cluster" "cluster" {
  for_each = toset(data.aws_eks_clusters.clusters.names)
  name     = each.value
}

output "output_terraform_md_eks_cluster" {
    value   =  aws_eks_cluster.eks_cluster
}

output "output_terraform_md_eks_clusters" {
    value   =  { for name in toset(data.aws_eks_clusters.clusters.names) : name => data.aws_eks_cluster.cluster[name]  }
}

output "output_terraform_md_eks_cluster_oidc_providers" {
    value   =  { for name in toset(data.aws_eks_clusters.clusters.names) : name => data.aws_eks_cluster.cluster[name].identity[0].oidc[0].issuer  }
}