locals {

    aws_region                                  =   "us-west-2"
    infra_modules_repo                          =   "bitbucket.org/Cpinto0594/terragrunt-infra"

    region_tags = {
        region = local.aws_region
    }

    #Module IAM
    aws_iam_config                              =   yamldecode(file("../../configs/iam_config.yaml"))
    
    #Roles for Infrastructure configuratiion
    aws_core_roles                              =   local.aws_iam_config.aws_core_roles #initial aws configuration
    aws_core_policies                           =   local.aws_iam_config.aws_core_policies #initial aws configuration
    aws_core_users                              =   local.aws_iam_config.aws_core_users #initial aws configuration

}