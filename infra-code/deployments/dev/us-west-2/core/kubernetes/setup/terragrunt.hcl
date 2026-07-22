
locals {
  terra_infra_repo    = local.region_vars.locals.infra_modules_repo
  terra_mod_name = "infra-modules/_bootstrap/kubernetes-setup"
  terra_mod_version = "v0.0.1"

  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  namespace_vars   = read_terragrunt_config(find_in_parent_folders("namespace.hcl"))

  kube_config      = yamldecode(file("../../../../../configs/kube_config.yaml"))

  cluster_name                                =   "${local.namespace_vars.locals.environment}_infra_cluster"

  kube_namespaces                             =   local.kube_config.kube_namespaces
  kube_service_accounts                       =   local.kube_config.kube_infra_service_accounts
  kube_role_bindings                          =   local.kube_config.kube_role_bindings
  kube_cluster_roles                          =   local.kube_config.kube_cluster_roles

  cert_manager_email                          =   local.account_vars.locals.cert_manager_email
  r53_domain_name                             =   local.account_vars.locals.r53_domain_name
  master_domain                               =   local.account_vars.locals.master_domain


  base_source = "${dirname(find_in_parent_folders("root.hcl"))}/..//${local.terra_mod_name}"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  //source = "git::${local.terra_infra_repo}/${terra_mod_name}?ref=${local.terra_mod_version}"
  source = "${local.base_source}"
}

inputs = {
    aws_vpc                                     =   "app_vpc"
   
    #Module Kubernetes Set up - see defaults in infra-modules/_bootstrap/kubernetes/setup
       
    #Module Kubernetes Preparation
    kube_namespaces                             =   local.kube_namespaces
    kube_service_accounts                       =   local.kube_service_accounts
    kube_role_bindings                          =   local.kube_role_bindings
    kube_cluster_roles                          =   local.kube_cluster_roles


    cert_manager_email                          =   local.cert_manager_email
    r53_domain_name                             =   local.r53_domain_name
    master_domain                               =   local.master_domain
    kube_cluster_name                           =   local.cluster_name
    #kube_cluster_name                           =   dependency.installation.outputs.output_terraform_md_eks_cluster

    #default_tags = merge( local.namespace_vars.locals.namespace_tags, local.region_vars.locals.region_tags, {terraform: true} )
}


dependencies {
  paths = [ "../../main", "../installation" ]
}