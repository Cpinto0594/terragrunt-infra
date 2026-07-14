locals {
    account_vars                =   read_terragrunt_config(find_in_parent_folders("account.hcl"))

    account_id                  =   local.account_vars.locals.account_id
    namespace                   =   "iac-core"
    version                     =   "1.0.0"        
    environment                 =   local.account_vars.locals.environment
    owner                       =   "devops"
    custodian                   =   "cpinto"
    state_bucket                =   "iac-terra-${local.namespace}-${local.version}-bucket" 
    dynamodb_table              =   "dynamo-${local.namespace}-${local.version}-table"
    region_name                 =   "us-west-2"

    namespace_tags = {
        namespace      = local.namespace
        environment    = local.environment
        owner          = local.owner
        custodian      = local.custodian
    }

    kube_config                                 =   yamldecode(file("../../../configs/kube_config.yaml"))
    kube_node_groups                            =   local.kube_config.kube_node_groups

    kube_infra_service_accounts                 =   local.kube_config.kube_infra_service_accounts
    kube_namespaces                             =   local.kube_config.kube_namespaces
    kube_role_bindings                          =   local.kube_config.kube_role_bindings
    kube_cluster_roles                          =   local.kube_config.kube_cluster_roles

    kube_service_accounts                       =   merge( {} , local.kube_infra_service_accounts )

    codebuild_config                            =   yamldecode(file("../../../configs/codebuild_config.yaml"))
    iac_core_codebuild_projects                 =   { for project_name, project_config in local.codebuild_config.iac_core_codebuild_projects : 
                                                            project_name => merge(project_config , {"environment": {"env_vars": concat( project_config.environment.env_vars, [ 
                                                                { "name"    :   "region",                 "value"   :   local.region_name },
                                                                { "name"    :   "environment",            "value"   :   local.environment },
                                                                { "name"    :   "account_id",             "value"   :   local.account_id }
                                                            ]
                                                        )}})
                                                    }
    iac_core_codepipeline_projects              =   { for project, config  in local.codebuild_config.iac_core_codebuild_projects : project => {
                                                        "service_role"           :  config.service_role ,
                                                        "name"                   : "iac_bootstrap_${project}_${local.environment}",
                                                        "stages_template"        : "iac_projects_stages" ,
                                                        "actions":               {
                                                            "Plan":         {
                                                                "ProjectName" : "iac_bootstrap_${project}_${local.environment}_plan"
                                                            },
                                                            "Apply":{
                                                                "ProjectName" : "iac_bootstrap_${project}_${local.environment}_apply"
                                                            }
                                                        }
                                                    }}    
}