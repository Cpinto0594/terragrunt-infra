locals {
  master_domain                    = var.master_domain
  headlamp_domain_name             = "headlamp.${var.r53_domain_name}"
  namespace_name                   = "${var.environment}-kube-monitoring"
  basic_auth_secret_name           = "${var.environment}-headlamp-basic-auth"
  headlamp_certificate_name        = "${var.environment}-headlamp-certificate"
  headlamp_certificate_secret_name = "${var.environment}-headlamp-certificate-secret-tls"
  headlamp_service_name            = "${var.environment}-headlamp"

  headlamp_resource_enabled         = 1
}


# 2. Store your basic authentication user/password pair
# Generates an Apache htpasswd file content (Username: admin / Password: MySecurePassword123)
# To generate a custom one, use the shell command: htpasswd -nb user pass
resource "kubernetes_secret_v1" "basic_auth" {
  count = local.headlamp_resource_enabled
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
  count      = local.headlamp_resource_enabled

  name       = local.headlamp_service_name
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
        type = "LoadBalancer"
        port = 80

        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
          "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"

          # 1. REMOVIDO: Se elimina 'backend-protocol = "ssl" / "external"' para evitar que AWS 
          # fuerce TLS de manera errónea en los puertos equivocados del contenedor.

          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "tcp"
          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"     = "traffic-port"
          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path"     = ""
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

########## TEMPORAL WHILE THE AWS ROUTE 53 REGISTRATION IS NOT DONE ##########
data "kubernetes_service_v1" "headlamp_service" {
  count = local.headlamp_resource_enabled
  metadata {
    name      = local.headlamp_service_name
    namespace = local.namespace_name
  }

  # Forces Terraform to wait until the Helm chart finishes deploying the resource
  depends_on = [helm_release.headlamp]
}


resource "cloudflare_dns_record" "headlamp_loadbalancer_dns_record" {
  count   = local.headlamp_resource_enabled
  zone_id = data.cloudflare_zone.infra_zone.id
  name    = "headlamp.${local.master_domain}"
  ttl     = 1
  type    = "CNAME"
  comment = "Headlamp Domain verification record"
  content = data.kubernetes_service_v1.headlamp_service[0].status[0].load_balancer[0].ingress[0].hostname
  proxied = true

  # tags = toset([
  #   for key, value in merge(local.tags, {
  #     Name = "grafana.${var.master_domain}"
  #   }) : "${key}:${value}"
  # ])
}
