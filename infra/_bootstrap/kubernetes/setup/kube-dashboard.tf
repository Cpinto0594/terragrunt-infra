
locals {
  dashboard_namespace           =   "${var.environment}-kubernetes-dashboard"
  dashboard_name                =   "${var.environment}-kubernetes-dashboard"
  dashboard_ingress             =   "${local.dashboard_name}"
  dashboard_ingress_tls_secret  =   "${local.dashboard_name}-tls"
  domain                        =   "dashboard.${var.environment}.renderapps.net"
}


resource "helm_release" "kubernetes-dashboard" {

  name =  local.dashboard_name

  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  namespace  = local.dashboard_namespace

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "protocolHttp"
    value = "true"
  }

  set {
    name  = "service.externalPort"
    value = 80
  }

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "rbac.clusterReadOnlyRole"
    value = "true"
  }

  depends_on = [
        data.aws_eks_node_groups.eks_cluster_node_groups,
        kubernetes_namespace.namespaces
  ]

}


resource "kubectl_manifest" "ingress_for_kube_dashboard" {
    yaml_body = <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: ${local.dashboard_namespace}
  name: ${local.dashboard_ingress}
  labels:
    app.kubernetes.io/name: ${local.dashboard_ingress}
    app.kubernetes.io/part-of: ${local.dashboard_namespace}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    cert-manager.io/cluster-issuer: ${local.cluster_issuer_name}
spec:
  tls:
    - hosts:
        - ${local.domain}
      secretName: ${local.dashboard_ingress_tls_secret}
  rules:
    - host: ${local.domain}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${local.dashboard_name}-kong-proxy
                port:
                  number: 443
EOF

  depends_on = [
        helm_release.kubernetes-dashboard
  ]
}


resource "kubectl_manifest" "dashboard_tls_cert_secret" {
  apply_only    = true
  ignore_fields = ["data", "annotations"]
  yaml_body     = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ${local.dashboard_ingress_tls_secret}
  namespace: ${local.dashboard_namespace}
data:
  tls.crt: ""
  tls.key: ""
YAML

  depends_on = [
        helm_release.kubernetes-dashboard ,
        data.aws_eks_node_groups.eks_cluster_node_groups 
  ]
} 