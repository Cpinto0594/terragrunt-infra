locals {
  temp_secrets   = yamldecode(file("./temp_secrets.yaml"))



  tg_role_name                = "Developer"
  master_domain               = "capilabs.dev"
  cert_manager_email          = "cpinto0594@gmail.com"

  cloudflare_access_token     = local.temp_secrets.cloudflare_access_token
}
