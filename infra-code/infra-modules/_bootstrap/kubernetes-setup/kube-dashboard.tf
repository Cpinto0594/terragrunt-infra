
locals {
  dashboard_namespace          = "${var.environment}-kube-monitoring"
  dashboard_name               = "${var.environment}-kubernetes-dashboard"
  dashboard_ingress            = local.dashboard_name
  dashboard_ingress_tls_secret = "${local.dashboard_name}-tls"
  domain                       = "dashboard.${var.r53_domain_name}"
  dashboard_resource_enabled   = 0
}

#https://github.com/kubernetes-retired/dashboard
resource "helm_release" "kubernetes-dashboard" {
  count = local.dashboard_resource_enabled

  name = local.dashboard_name

  repository = "https://kubernetes-retired.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  namespace  = local.dashboard_namespace

  set = [
    {
      name  = "service.type"
      value = "LoadBalancer"
    },

    {
      name  = "protocolHttp"
      value = "true"
    },

    {
      name  = "service.externalPort"
      value = 80
    },

    {
      name  = "replicaCount"
      value = 1
    },

    {
      name  = "rbac.clusterReadOnlyRole"
      value = "true"
    },
    {
      name  = "kong.proxy.type"
      value = "LoadBalancer"
      #set to loadbalancer to expose the dashboard externally, set to ClusterIP to expose it internally only
      # then get the external ip of the loadbalancer and create a route53 record to point to it, then access the dashboard via the route53 record
      # kubectl get svc dev-kubernetes-dashboard-kong-proxy -n dev-kube-monitoring -w
    },
    {
      name  = "kong.proxy.http.enabled"
      value = "true"
    }
  ]

  depends_on = [
    data.aws_eks_node_groups.eks_cluster_node_groups,
    kubernetes_namespace_v1.namespaces,
  ]

}


resource "kubectl_manifest" "ingress_for_kube_dashboard" {
  count     = local.dashboard_resource_enabled
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
    helm_release.kubernetes-dashboard,
    kubectl_manifest.cluster_issuer
  ]
}


resource "kubectl_manifest" "dashboard_tls_cert_secret" {
  count         = local.dashboard_resource_enabled
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
    helm_release.kubernetes-dashboard,
    data.aws_eks_node_groups.eks_cluster_node_groups
  ]
}



data "kubernetes_service_v1" "kube_dashboard_service_kong_proxy" {
  count = local.dashboard_resource_enabled
  
  metadata {
    name      = "${local.dashboard_name}-kong-proxy"
    namespace = local.dashboard_namespace
  }

  # Forces Terraform to wait until the Helm chart finishes deploying the resource
  depends_on = [helm_release.kubernetes-dashboard]
}


resource "cloudflare_dns_record" "kube_dashboard_loadbalancer_dns_record" {
  count   = local.dashboard_resource_enabled

  zone_id = data.cloudflare_zone.infra_zone.id
  name    = "kube-dashboard.${var.master_domain}"
  ttl     = 1
  type    = "CNAME"
  comment = "Kubernetes Dashboard Domain verification record"
  content = data.kubernetes_service_v1.kube_dashboard_service_kong_proxy[0].status[0].load_balancer[0].ingress[0].hostname
  proxied = true

  # tags = toset([
  #   for key, value in merge(local.tags, {
  #     Name = "grafana.${var.master_domain}"
  #   }) : "${key}:${value}"
  # ])
  depends_on = [helm_release.kubernetes-dashboard, data.kubernetes_service_v1.kube_dashboard_service_kong_proxy]
}
