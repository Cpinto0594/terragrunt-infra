
locals {
  terra_infra_repo  = local.region_vars.locals.infra_modules_repo
  terra_mod_name    = "infra-modules/module-rds-cluster-instance"
  terra_mod_version = "v0.0.1"

  account_vars      = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars       = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  namespace_vars    = read_terragrunt_config(find_in_parent_folders("namespace.hcl"))

  base_source = "${dirname(find_in_parent_folders("root.hcl"))}/..//${local.terra_mod_name}"
}

include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  //source = "git::${local.terra_infra_repo}/${terra_mod_name}?ref=${local.terra_mod_version}"
  source = "${local.base_source}"

}

inputs = {

    project                           =   "rds-cluster-instance"
    r53_domain_name                   =   local.account_vars.locals.r53_domain_name
    route_53_record_prefix            =   "raffle-db"

    # Cluster data
    cluster_identifier                =   "raffle-db-cluster-${local.namespace_vars.locals.environment}",
    port                              =   54321,
    engine_version                    =   "15.4"
    #at minimun 3 AZ
    availability_zones                =   ["us-west-2a" , "us-west-2b", "us-west-2c"],
    cluster_database_name             =   "raffle_db" ,
    master_username                   =   "raffledb_master_user" ,
    master_password                   =   "raffledb_master_password" ,
    enabled_cloudwatch_logs_exports   =   ["postgresql"] ,
    vpc_security_group_ids            =   ["postgresql_db_security_group"]

    #Cluster Instance data 
    instance_identifier               = "raffle-db-inst-${local.namespace_vars.locals.environment}",
    cluster_name                      = "raffle-db-cluster-${local.namespace_vars.locals.environment}",


    #default_tags = merge( local.namespace_vars.locals.namespace_tags, local.region_vars.locals.region_tags )
}