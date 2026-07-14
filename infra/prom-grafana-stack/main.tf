locals {

  # Define an htpasswd file for basic auth to alertmanager
  basic_auth = <<-AUTH
    admin:${random_password.prometheus.bcrypt_hash}
  AUTH

  dns_domain                        =   var.dns_domain
  namespace                         =   "${var.environment}-prom-grafana-stack"
  
  # Define a values file for the prometheus helm chart
  kube_prometheus_stack_values = <<-VALUES
    prometheus:
      prometheusSpec:
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: gp2
              accessModes: ["ReadWriteOnce"]
              persistentVolumeReclaimPolicy: Retain
              finalizers:
                - kubernetes.io/pvc-protection
              resources:
                requests:
                  storage: 30Gi
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
            secretName: alertmanager-tls
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
        enabled: true
        hosts:
          - grafana.${local.dns_domain}
        tls:
          - hosts:
              - grafana.${local.dns_domain}
            secretName: grafana-tls
      service:
        type: ClusterIP
      persistence:
        enabled: true
        type: pvc
        storageClassName: gp2
        accessModes:
        - ReadWriteOnce
        size: 4Gi
        persistentVolumeReclaimPolicy: Retain
        finalizers:
        - kubernetes.io/pvc-protection
  VALUES
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
resource "helm_release" "kube-prometheus-stack" {
  count      = 1
  name       = "kube-prometheus-stack"
  namespace  = local.namespace
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "45.18.0"
  values     = [local.kube_prometheus_stack_values]
  create_namespace = true
  
}

# resource "kubectl_manifest" "storage_class_disk_fast" {
#     yaml_body = <<EOF
#     kind: StorageClass
#     apiVersion: storage.k8s.io/v1
#     metadata:
#       name: ebs-storage-prometheus
#     provisioner: ebs.csi.aws.com
#     allowVolumeExpansion: true
#     volumeBindingMode: WaitForFirstConsumer
# EOF
# depends_on = [ data.aws_eks_cluster.eks_cluster ]
# }


# # Create a Secret Manager Secret to store the prometheus password
# resource "google_secret_manager_secret" "prometheus-password" {
#   project   = google_project.project.project_id
#   secret_id = "prometheus-password"

#   replication {
#     auto = true
#   }
# }

# # Store the prometheus password in the Secret Manager Secret
# resource "google_secret_manager_secret_version" "prometheus-password" {
#   secret      = google_secret_manager_secret.prometheus-password.id
#   secret_data = random_password.prometheus.result
# }
