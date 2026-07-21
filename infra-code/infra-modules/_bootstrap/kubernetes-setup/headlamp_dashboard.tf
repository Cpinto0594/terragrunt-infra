locals {
  headlamp_domain_name             = "headlamp.${var.r53_domain_name}"
  namespace_name                   = "${var.environment}-kube-monitoring"
  basic_auth_secret_name           = "${var.environment}-headlamp-basic-auth"
  headlamp_certificate_name        = "${var.environment}-headlamp-certificate"
  headlamp_certificate_secret_name = "${var.environment}-headlamp-certificate-secret-tls"
}


# 2. Store your basic authentication user/password pair
# Generates an Apache htpasswd file content (Username: admin / Password: MySecurePassword123)
# To generate a custom one, use the shell command: htpasswd -nb user pass
resource "kubernetes_secret_v1" "basic_auth" {
  metadata {
    name      = local.basic_auth_secret_name
    namespace = local.namespace_name
  }

  data = {
    # Replace this string with your custom htpasswd content if desired
    "auth" = "admin:$apr1$yL6p9g37$vjV8C0VkWz0VwX9p9v7n2/"
  }
}

# 3. Primary Helm deployment for Headlamp
resource "helm_release" "headlamp" {
  name       = "${var.environment}-headlamp"
  repository = "https://kubernetes-sigs.github.io/headlamp"
  chart      = "headlamp"
  version    = "0.43.0"
  namespace  = local.namespace_name
  wait       = false

  values = [
    yamlencode({
      # Configures Headlamp base path settings
      config = {
        baseURL = "" # Clear if mapping cleanly to a dedicated root domain
      }

      args = [
        "-in-cluster",
        "-allowed-hosts=*",
        "-username-password-file=/etc/headlamp-auth/auth"
      ]

      volumes = [
        {
          name = "${var.environment}-headlamp-auth-volume"
          secret = {
            secretName = local.basic_auth_secret_name
          }
        }
      ]

      volumeMounts = [
        {
          name      = "${var.environment}-headlamp-auth-volume"
          mountPath = "/etc/headlamp-auth"
          readOnly  = true
        }
      ]

      service = {
        type       = "LoadBalancer"
        port       = 80

        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
          "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"

          # Passes raw encrypted traffic directly to the self-signed pod
          "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"

          # Health check must look for HTTPS now
          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "http"
          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path"     = ""
          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"     = "traffic-port"
        }
      }


      # Resource management parameters
      resources = {
        limits   = { cpu = "500m", memory = "512Mi" }
        requests = { cpu = "100m", memory = "128Mi" }
      }
    })
  ]

  depends_on = [
    kubernetes_secret_v1.basic_auth
  ]
}

# resource "kubectl_manifest" "headlamp_letsencrypt_cert" {
#   yaml_body = <<YAML
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: ${local.headlamp_certificate_name}
#   namespace: ${local.networking_namespace}
# spec:
#   secretName: ${local.headlamp_certificate_secret_name}
#   issuerRef:
#     name: ${local.cluster_issuer_name}
#     kind: ClusterIssuer
#   dnsNames:
#     - "capilabs.dev"
# YAML
#   lifecycle {
#     ignore_changes = []
#   }

# }

# resource "kubectl_manifest" "headlamp_tls_cert_secret" {
#   apply_only    = true
#   ignore_fields = ["data", "annotations"]
#   yaml_body     = <<YAML
# apiVersion: v1
# kind: Secret
# metadata:
#   name: ${local.headlamp_certificate_secret_name}
#   namespace: ${local.namespace_name}
# data:
#   tls.crt: ""
#   tls.key: ""
# YAML

# }
