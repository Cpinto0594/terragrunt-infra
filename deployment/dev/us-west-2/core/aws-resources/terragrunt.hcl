
locals {
  terra_infra_repo    = local.region_vars.locals.infra_modules_repo
  terra_mod_name = "infra/core-modules/module-iam"
  terra_mod_version = "v0.0.1"

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
    #Module IAM
    managed_infra_roles                     = local.region_vars.locals.aws_core_roles
    managed_infra_policies                  = local.region_vars.locals.aws_core_managed_policies
    managed_infra_users                     = local.region_vars.locals.aws_core_users

    #default_tags = merge( local.namespace_vars.locals.namespace_tags, local.region_vars.locals.region_tags, {terraform: true} )
}