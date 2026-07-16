locals {
  cert_manager_version        = "v1.14.4"
  cluster_issuer_name         = "${var.environment}-letsencrypt"
}


resource "helm_release" "cert-manager" {
  name             = "${var.environment}-cert-manager"
  namespace        = local.networking_namespace
  create_namespace = false
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = local.cert_manager_version
  
  values = [
    file("${path.module}/resources/manifests/cert-manager.yaml")
  ]

  depends_on = [
    data.aws_eks_node_groups.eks_cluster_node_groups
  ]
}


# #This is stagging server
# #https://acme-staging-v02.api.letsencrypt.org/directory
# #this is Prod server 
# #https://acme-v02.api.letsencrypt.org/directory

resource "kubectl_manifest" "cluster_issuer" {
    yaml_body = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${local.cluster_issuer_name}
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${var.cert_manager_email}
    privateKeySecretRef:
      name: ${local.cluster_issuer_name}
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

depends_on = [
    helm_release.cert-manager
  ]
}