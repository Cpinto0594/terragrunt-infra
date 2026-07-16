
locals {
  terra_infra_repo    = local.region_vars.locals.infra_modules_repo
  terra_mod_name = "infra-modules/_bootstrap/kubernetes"
  terra_mod_version = "v0.0.1"

  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  namespace_vars   = read_terragrunt_config(find_in_parent_folders("namespace.hcl"))

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

    #Module Kubernete - see defaults in infra-modules/core-modules/module-kubernetes
    cluster_name                                =   "${local.namespace_vars.locals.environment}_infra_cluster"
    oidc_enabled                                =   true
    # role_arn                                    =   var.role_arn   #cluster role arn
    # cluster_security_groups                     =   var.cluster_security_groups
    # logs_retention_days                         =   var.logs_retention_days
    # cluster_version                             =   var.cluster_version
    # enabled_cluster_log_types                   =   var.enabled_cluster_log_types
    kube_node_groups                            =   local.namespace_vars.locals.kube_node_groups
    cluster_addons                              =   [ { name = "aws-ebs-csi-driver", service_account_name = "AmazonEKS_EBS_CSI_DriverRole" } ]
                                                          #service_account_arn: "arn:aws:iam::${local.account_vars.locals.account_id}:role/AmazonEKSPodIdentityAmazonEFSCSIDriverRole" 
    #Module Kubernetes Preparation
    kube_namespaces                             =   local.namespace_vars.locals.kube_namespaces
    kube_service_accounts                       =   local.namespace_vars.locals.kube_infra_service_accounts
    kube_role_bindings                          =   local.namespace_vars.locals.kube_role_bindings
    kube_cluster_roles                          =   local.namespace_vars.locals.kube_cluster_roles
    external_dns_role_arn                       =   local.account_vars.locals.tg_role_name

    #default_tags = merge( local.namespace_vars.locals.namespace_tags, local.region_vars.locals.region_tags, {terraform: true} )
}

dependencies {
  paths = [ "../main" ]
}