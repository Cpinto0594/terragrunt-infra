locals {
  #apps_config   = yamldecode(file("./configs/apps.yaml")).defaults



  tg_role_name                = "Developer"
  master_domain               = "capilabs.dev"
  cert_manager_email          = "cpinto0594@gmail.com"
}
