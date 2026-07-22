locals {

  # Define an htpasswd file for basic auth to alertmanager
  basic_auth = <<-AUTH
    admin:${random_password.prometheus.bcrypt_hash}
  AUTH

  alert_manager_secret_name = "${var.environment}-alertmanager-tls"
  grafana_secret_name       = "${var.environment}-grafana-tls"
  stack_name                = "${var.environment}-kube-prometheus-stack2"
  grafana_service_name      = "${local.stack_name}-grafana"

  dns_domain                =  var.dns_domain
  master_domain             = var.master_domain
  namespace  = "${var.environment}-kube-monitoring"

  # Define a values file for the prometheus helm chart
  kube_prometheus_stack_values = <<-VALUES
    prometheus:
      prometheusSpec:
        retention: 10d
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: gp3
              accessModes: ["ReadWriteOnce"]
              # REMOVED: persistentVolumeReclaimPolicy and finalizers do not belong here
              resources:
                requests:
                  storage: 20Gi
    alertmanager:
      ingress:
        annotations:
          cert-manager.io/cluster-issuer: cert-manager
          kubernetes.io/ingress.class: nginx
          nginx.ingress.kubernetes.io/auth-realm: Authentication Required
          nginx.ingress.kubernetes.io/auth-secret: prometheus-auth
          nginx.ingress.kubernetes.io/auth-type: basic
          nginx.ingress.kubernetes.io/ssl-redirect: "true"
        enabled: true
        hosts:
          - alertmanager.${local.dns_domain}
        tls:
          - hosts:
              - alertmanager.${local.dns_domain}
            secretName: ${local.alert_manager_secret_name}
      service:
        type: ClusterIP
    grafana:
      adminPassword: ${random_password.prometheus.result}
      adminUser: admin
      ingress:
        annotations:
          cert-manager.io/cluster-issuer: cert-manager
          kubernetes.io/ingress.class: nginx
          nginx.ingress.kubernetes.io/ssl-redirect: "true"
        enabled: false
        hosts:
          - grafana.${local.dns_domain}
        tls:
          - hosts:
              - grafana.${local.dns_domain}
            secretName: ${local.grafana_secret_name}
      service:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
          service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: "tcp"
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: "traffic-port"
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: ""
        enabled: true
      persistence:
        enabled: true
        storageClassName: "gp3"
        accessModes:
        - ReadWriteOnce
        size: 4Gi
  VALUES

  tags = var.default_tags
}

# Create a random password to use for prometheus apps
resource "random_password" "prometheus" {
  length  = 16
  special = false
}

# Create a kubernetes secret to store the promethues password
resource "kubernetes_secret_v1" "prometheus-auth" {
  count = 1
  type  = "Opaque"

  metadata {
    name      = "prometheus-auth"
    namespace = local.namespace
  }

  data = {
    auth = local.basic_auth
  }

}

# Install prometheus using a helm chart
resource "helm_release" "kube-prometheus-stack_release" {
  count            = 1
  name             = local.stack_name
  namespace        = local.namespace
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  version          = "87.17.0"
  values           = [local.kube_prometheus_stack_values]
  create_namespace = false

  # Highlighted: Force upgrade if a release already exists
  force_update  = true
  recreate_pods = true

  # Ensure timeouts are long enough for CRD creation
  wait    = true
  timeout = 600


  depends_on = [data.aws_eks_cluster.eks_cluster, kubectl_manifest.storage_class_disk_gp3]
}

resource "kubectl_manifest" "storage_class_disk_gp3" {

  yaml_body  = <<EOF
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: gp3
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    allowVolumeExpansion: true
    parameters:
      type: gp3
      fsType: ext4
      encrypted: "true"
EOF
  depends_on = [data.aws_eks_cluster.eks_cluster]
}

data "kubernetes_service_v1" "grafana_service" {
  metadata {
    name      = local.grafana_service_name
    namespace = local.namespace
  }

  # Forces Terraform to wait until the Helm chart finishes deploying the resource
  depends_on = [helm_release.kube-prometheus-stack_release]
}


data "cloudflare_zone" "infra_zone" {
  filter = {
    name = var.master_domain
  }
}

resource "cloudflare_dns_record" "grafana_loadbalancer_dns_record" {
  count   = 1
  zone_id = data.cloudflare_zone.infra_zone.id
  name    = "grafana.${var.master_domain}"
  ttl     = 1
  type    = "CNAME"
  comment = "Grafana Domain verification record"
  content = data.kubernetes_service_v1.grafana_service.status[0].load_balancer[0].ingress[0].hostname
  proxied = true

  # tags = toset([
  #   for key, value in merge(local.tags, {
  #     Name = "grafana.${var.master_domain}"
  #   }) : "${key}:${value}"
  # ])
}
