locals {
    account_vars                =   read_terragrunt_config(find_in_parent_folders("account.hcl"))

    account_id                  =   local.account_vars.locals.account_id
    namespace                   =   "iac-aws-core"
    version                     =   "1.0.0"        
    environment                 =   local.account_vars.locals.environment
    owner                       =   "devops"
    custodian                   =   "cpinto"
    state_bucket                =   "iac-terra-${local.namespace}-${local.version}-bucket" 

    namespace_tags = {
        namespace      = local.namespace
        environment    = local.environment
        owner          = local.owner
        custodian      = local.custodian
    }
}