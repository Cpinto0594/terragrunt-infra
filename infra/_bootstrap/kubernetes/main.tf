locals {
  vpc_id = var.aws_vpc
}

module "module_kubernetes" {
  source = "../../core-modules/module-kubernetes"

  environment                   =   var.environment
  aws_region                    =   var.aws_region
  account_id                    =   var.account_id
  default_tags                  =   var.default_tags

  subnet_ids                    =   toset(data.aws_subnets.subnets.ids)
  vpc_id                        =   data.aws_vpcs.app_vpc.id

  cluster_name                  =   var.cluster_name
  role_arn                      =   var.role_arn
  cluster_security_groups       =   var.cluster_security_groups
  logs_retention_days           =   var.logs_retention_days
  cluster_version               =   var.cluster_version
  enabled_cluster_log_types     =   var.enabled_cluster_log_types
  kube_node_groups              =   var.kube_node_groups
  oidc_enabled                  =   var.oidc_enabled
  cluster_addons                =   var.cluster_addons
}


module "module_core_setup_kubernetes" {
  source = "./setup"
  environment                               =   var.environment
  aws_region                                =   var.aws_region
  account_id                                =   var.account_id
  default_tags                              =   var.default_tags

  kube_namespaces                           =   var.kube_namespaces
  kube_service_accounts                     =   var.kube_service_accounts
  kube_role_bindings                        =   var.kube_role_bindings
  kube_cluster_roles                        =   var.kube_cluster_roles
  cert_manager_email                        =   var.cert_manager_email
  r53_domain_name                           =   var.r53_domain_name
  kube_cluster_name                         =   module.module_kubernetes.output_terraform_md_eks_cluster.id
  external_dns_role_arn                     =   var.external_dns_role_arn 
}

data "aws_vpcs" "app_vpc" {
  tags = {
    Name = local.vpc_id
  }
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = toset(data.aws_vpcs.app_vpc.ids)
  }
}
