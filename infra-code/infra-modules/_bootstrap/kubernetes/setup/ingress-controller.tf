locals {
  #ingress_nginx_namespace = "${var.environment}-ingress"
  helm_release            = "${var.environment}-ingress-nginx"
  nginx_helm_version      = "4.10.0"
}

resource "helm_release" "ingress-nginx" {
  name             = local.helm_release
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = local.networking_namespace
  version          = local.nginx_helm_version
  create_namespace = false

  set = [{
    name  = "rbac.create"
    value = "true"
  }]

  depends_on = [
    data.aws_eks_node_groups.eks_cluster_node_groups,
    kubernetes_namespace_v1.namespaces
  ]

}


resource "kubernetes_config_map_v1" "ingress-nginx-controller" {
  metadata {
    name = local.helm_release
    annotations = {
      "meta.helm.sh/release-name"      = local.helm_release
      "meta.helm.sh/release-namespace" = local.networking_namespace
    }
    labels = {
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/instance"   = local.helm_release
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/part-of"    = "ingress-nginx"
      "app.kubernetes.io/version"    = "2.27.0"
      "helm.sh/chart"                = "ingress-nginx-${local.nginx_helm_version}"
    }
  }
  data = {
    "allow-snippet-annotations" = var.environment == "dev" ? null : "true"
    "client-body-buffer-size"   = var.environment == "dev" ? null : "32k"
    "ssl-ciphers"               = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:TLS_CHACHA20_POLY1305_SHA256:DHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES256-SHA256:ECDHE-ECDSA-AES128-SHA256:DHE-RSA-AES128-SHA256"
  }
  depends_on = [
    helm_release.ingress-nginx
  ]
}
