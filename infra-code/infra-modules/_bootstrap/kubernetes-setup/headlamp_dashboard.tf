locals {
  headlamp_domain_name = "headlamp.${var.r53_domain_name}"
}

# 1. Create the dedicated headlamp namespace
resource "kubernetes_namespace_v1" "headlamp" {
  metadata {
    name = "headlamp"
  }
}

# 2. Store your basic authentication user/password pair
# Generates an Apache htpasswd file content (Username: admin / Password: MySecurePassword123)
# To generate a custom one, use the shell command: htpasswd -nb user pass
resource "kubernetes_secret_v1" "basic_auth" {
  metadata {
    name      = "headlamp-basic-auth"
    namespace = kubernetes_namespace_v1.headlamp.metadata[0].name
  }

  data = {
    # Replace this string with your custom htpasswd content if desired
    "auth" = "admin:$apr1$yL6p9g37$vjV8C0VkWz0VwX9p9v7n2/"
  }
}

# 3. Primary Helm deployment for Headlamp
resource "helm_release" "headlamp" {
  name       = "headlamp"
  repository = "https://kubernetes-sigs.github.io/headlamp"
  chart      = "headlamp"
  version    = "0.43.0"
  namespace  = kubernetes_namespace_v1.headlamp.metadata[0].name

  values = [
    yamlencode({
      # Configures Headlamp base path settings
      config = {
        baseURL = "" # Clear if mapping cleanly to a dedicated root domain
      }

      args = [
        "-in-cluster",
      ]

      # 4. Ingress configuration with Basic Auth annotations
      ingress = {
        enabled          = false
        ingressClassName = "alb"

        hosts = [
          {
            host = local.headlamp_domain_name # Update to your local or real domain
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
                type     = "Prefix"

              }
            ]
          }
        ]

        annotations = {

          "kubernetes.io/ingress.class" = "nginx"
          # Links NGINX directly to our basic auth credential secret
          "nginx.ingress.kubernetes.io/auth-type"   = "basic"
          "nginx.ingress.kubernetes.io/auth-secret" = "headlamp-basic-auth"
          "nginx.ingress.kubernetes.io/auth-realm"  = "Authentication Required - Headlamp"
        }
      }

      service = {
        type       = "LoadBalancer"
        port       = 80
        targetPort = "http"


        # AWS Specific annotations for the Service object
        annotations = {
          # Specifies the type of load balancer. 'nlb-ip' is modern and recommended for AWS.
          "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
          "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"

          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "tcp"
          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"     = "traffic-port"
          "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path"     = ""

          # Links NGINX directly to our basic auth credential secret
          "nginx.ingress.kubernetes.io/auth-type"   = "basic"
          "nginx.ingress.kubernetes.io/auth-secret" = "headlamp-basic-auth"
          "nginx.ingress.kubernetes.io/auth-realm"  = "Authentication Required - Headlamp"

        }
      }


      # Resource management parameters
      resources = {
        limits   = { cpu = "500m", memory = "512Mi" }
        requests = { cpu = "100m", memory = "128Mi" }
      }
    })
  ]
}
