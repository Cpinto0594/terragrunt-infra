locals {
    globals_vars                                =    read_terragrunt_config(find_in_parent_folders("globals.hcl"))


    account_id                  =   "324711057459"
    environment                 =   "dev"
    tg_role_name                =   local.globals_vars.locals.tg_role_name
    master_domain               =   local.globals_vars.locals.master_domain
    r53_domain_name             =   "${local.environment}.${local.master_domain}"

    providers                   =   {
        aws                     =   {
            version             =   "6.54.0"
        }
        kubernetes              =   {
            version             =   "3.2.1"
        }
        helm                    =   {
            version             =   "3.2.0"
        }
        kubectl                 =   {
            version             =   "1.19.0"
        }
        time                    =   {
            version             =   "0.14.0"
        }
        random                  =   {
            version             =   "3.9.0"
        }
        tls                  =   {
            version             =   "4.3.0"
        }
    }
}