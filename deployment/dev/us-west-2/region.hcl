locals {

    aws_region                                  =   "us-west-2"
    infra_modules_repo                          =   "bitbucket.org/Cpinto0594/terragrunt-infra"

    globals_vars                                =    read_terragrunt_config(find_in_parent_folders("globals.hcl"))

    region_tags = {
        region = local.aws_region
    }

    #Module VPC
    #https://www.davidc.net/sites/default/subnets/subnets.html
    vpc_cidr                                    =   "10.192.0.0/20"
    private_route_cidrs                         =   ["0.0.0.0/0", "0.0.0.0/0", "0.0.0.0/0"]
    public_route_cidrs                          =   ["0.0.0.0/0" ]
    public_subnets_cidrs                        =   ["10.192.0.0/22", "10.192.4.0/23", "10.192.6.0/23"]
    private_subnets_cidrs                       =   ["10.192.8.0/22", "10.192.12.0/23", "10.192.14.0/23"]
    public_subnets_available_zones              =   ["us-west-2a", "us-west-2b", "us-west-2c"]
    private_subnets_available_zones             =   ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_route_tables                         =   ["1"]
    private_route_tables                        =   ["1","2", "3"]

    #Module Security Groups
    security_groups_config                      =   yamldecode(file("../../configs/security_groups_config.yaml"))
    infra_security_groups                       =   local.security_groups_config.infra_security_groups
    #apps_security_groups                        =   local.security_groups_config.apps_security_groups

    #Module IAM
    aws_iam_config                              =   yamldecode(file("../../configs/aws-core/iam_config.yaml"))
    iam_config                                  =   yamldecode(file("../../configs/iam_config.yaml"))
    app_roles_aws_service_list                  =   local.iam_config.app_roles_aws_service_list
    app_service_roles_managed_policies          =   local.iam_config.app_service_roles_managed_policies

   
    #Roles for Infrastructure configuratiion
    aws_core_roles                              =   local.aws_iam_config.aws_core_roles #initial aws configuration
    aws_core_managed_policies                   =   local.aws_iam_config.infra_managed_policies #initial aws configuration
    aws_core_users                              =   local.aws_iam_config.aws_core_users #initial aws configuration

    infra_core_roles                            =   local.iam_config.infra_core_roles
    infra_managed_policies                      =   local.iam_config.infra_managed_policies

    #Policies attached to app roles
    _app_services_roles_definition              =   {
                                                        path = "/service-role/",
                                                        managed_policies = [ for key, value in local.app_service_roles_managed_policies: key  ]
                                                        assume_role_policy = {
                                                            Version =  "2012-10-17",
                                                            Statement = [
                                                                {
                                                                    Effect = "Allow",
                                                                    Principal = {
                                                                        Service = local.app_roles_aws_service_list
                                                                    },
                                                                    Action = ["sts:AssumeRole"]
                                                                }
                                                            ]
                                                        }
                                                    }


    #App specific roles
    app_services_roles                          =   { for service, config in local.globals_vars.locals.apps_config : "${service}_service_role" => local._app_services_roles_definition }

    roles_computed                              =   merge(local.infra_core_roles, local.app_services_roles)
    managed_policies_computed                   =   merge( local.infra_managed_policies , local.app_service_roles_managed_policies)
   
    managed_infra_policies                      =  local.managed_policies_computed
    managed_infra_roles                         =  local.roles_computed
    
    apps_security_groups_computed               =   [ for app, config in local.globals_vars.locals.apps_config : 
                                                          merge(local.security_groups_config.apps_security_groups[config.lang], {name:  "${app}_service_sec_grp" })
                                                          if ( try( local.security_groups_config.apps_security_groups[config.lang], null ) != null )
                                                    ]
    apps_security_groups                        =   local.apps_security_groups_computed

}