locals {

    terra_infra_repo    = local.region_vars.locals.infra_modules_repo
    terra_mod_name = "infra/project-build"
    terra_mod_version = "v0.0.1"

    account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
    region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
    namespace_vars   = read_terragrunt_config(find_in_parent_folders("namespace.hcl"))

    base_source = "${dirname(find_in_parent_folders("root.hcl"))}/..//${local.terra_mod_name}"

    project                       =   "api"
    project_name                  =   "${local.namespace_vars.locals.namespace}_${local.project}_${local.namespace_vars.locals.environment}"
}


include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  //source = "git::${local.terra_infra_repo}/${terra_mod_name}?ref=${local.terra_mod_version}"
  source = "${local.base_source}"
}

inputs = {

  project                       =   local.project
  project_name                  =   local.project_name
  #service_role                 =   "${local.namespace_vars.locals.namespace}_${local.project}_service_role"
  #location                     =   "Cpinto0594/${local.namespace_vars.locals.namespace}-${local.project}.git"

  buildspec                     =   "buildspec-tf_java"

  #env_vars                      =   [ {name = "" , value = "" } ]

  subnet_ids                    =   [for key, value in dependency.bootstrap.outputs.output_vpc_mod_private_subnets : value.id]
  service_roles_arns            =   dependency.bootstrap.outputs.output_iam_mod_service_roles
  vpc_id                        =   dependency.bootstrap.outputs.output_vpc_mod_app_vpc_id

}


dependency "bootstrap" {
  config_path  = "../../../core/main" 
  mock_outputs   = {
    output_vpc_mod_private_subnets = {}
    output_sg_mod_security_groups = []
    output_iam_mod_service_roles = {}
    output_vpc_mod_app_vpc_id = ""
  }
}

dependencies {
  paths = [ "../../../core/main" ]
}