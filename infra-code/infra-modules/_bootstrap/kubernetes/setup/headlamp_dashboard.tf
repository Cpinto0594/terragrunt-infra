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

      # 4. Ingress configuration with Basic Auth annotations
      ingress = {
        enabled = true
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
          "kubernetes.io/ingress.class"      = "nginx"
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