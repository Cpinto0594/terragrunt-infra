
locals {
  terra_infra_repo    = local.region_vars.locals.infra_modules_repo
  terra_mod_name = "infra-modules/_bootstrap/module-core"
  terra_mod_version = "v0.0.1"

  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  namespace_vars   = read_terragrunt_config(find_in_parent_folders("namespace.hcl"))

  base_source = "${dirname(find_in_parent_folders("root.hcl"))}/..//${local.terra_mod_name}"

  #Temp variable to 
  iac_core_codebuild_projects_flatten               =   flatten([
                                                                for name , config in local.namespace_vars.locals.iac_core_codebuild_projects: [
                                                                      for operation in toset(["plan", "apply"]): 
                                                                      { name: "iac_bootstrap_${name}_${local.namespace_vars.locals.environment}_${operation}" , config: {
                                                                          name            : "iac_bootstrap_${name}_${local.namespace_vars.locals.environment}_${operation}" ,
                                                                          service_role    : config.service_role ,
                                                                          security_groups : config.security_groups ,
                                                                          environment     : config.environment ,
                                                                          artifacts       : "CODEPIPELINE" ,
                                                                          source :  {
                                                                              type            : "CODEPIPELINE" ,
                                                                              buildspec       : "Codebuild/bootstrap/buildspec-tf_${operation}.yml"
                                                                          }
                                                                        }
                                                                      }
                                                                ]
                                                      ])
  iac_core_codebuild_projects_computed              =  { for value in local.iac_core_codebuild_projects_flatten : value.name => value.config }

  iac_core_codepipeline_projects                    =  local.namespace_vars.locals.iac_core_codepipeline_projects 
 
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  //source = "git::${local.terra_infra_repo}/${terra_mod_name}?ref=${local.terra_mod_version}"
  source = "${local.base_source}"
}

inputs = {
    
    #Module VPC - Input Vars
    vpc_cidr                                =  local.region_vars.locals.vpc_cidr
    private_route_cidrs                     =  local.region_vars.locals.private_route_cidrs
    public_route_cidrs                      =  local.region_vars.locals.public_route_cidrs
    public_subnets_cidrs                    =  local.region_vars.locals.public_subnets_cidrs
    private_subnets_cidrs                   =  local.region_vars.locals.private_subnets_cidrs
    public_subnets_available_zones          =  local.region_vars.locals.public_subnets_available_zones
    private_subnets_available_zones         =  local.region_vars.locals.private_subnets_available_zones
    public_route_tables                     =  local.region_vars.locals.public_route_tables
    private_route_tables                    =  local.region_vars.locals.private_route_tables

    #Module Security Groups - Input Vars
    security_groups                         = local.region_vars.locals.infra_security_groups #concat( local.region_vars.locals.infra_security_groups , local.region_vars.locals.apps_security_groups )

    #Module IAM - Input Vars
    managed_infra_roles                     = local.region_vars.locals.managed_infra_roles
    managed_infra_policies                  = local.region_vars.locals.managed_infra_policies

    #Module CodeBuild - Check
    #iac_core_codebuild_projects             =   local.iac_core_codebuild_projects_computed
    #iac_core_codepipeline_projects          =   local.iac_core_codepipeline_projects

    #default_tags = merge( local.namespace_vars.locals.namespace_tags, local.region_vars.locals.region_tags, {terraform: true} )
}