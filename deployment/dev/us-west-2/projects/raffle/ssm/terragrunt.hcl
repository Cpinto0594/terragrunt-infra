
locals {
  terra_infra_repo    = local.region_vars.locals.infra_modules_repo
  terra_mod_name = "infra/module-ssm"
  terra_mod_version = "v0.0.1"

  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  namespace_vars   = read_terragrunt_config(find_in_parent_folders("namespace.hcl"))

  base_source = "${dirname(find_in_parent_folders())}/..//${local.terra_mod_name}"
}

include {
  path = find_in_parent_folders()
}

terraform {
  //source = "${local.terra_infra_repo}/${terra_mod_name}?ref=${local.terra_mod_version}"
  source = "${local.base_source}"
}

inputs = {
    project                       =   "ssm"

    #default_tags = merge( local.namespace_vars.locals.namespace_tags, local.region_vars.locals.region_tags )
}