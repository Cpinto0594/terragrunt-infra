locals {
    repository_location                         =   coalesce( var.location, "Cpinto0594/${var.namespace}-${var.project}.git" )
    raw_project_name                            =   "${var.namespace}_${var.project}"
    defaults                                    =   yamldecode(file("${path.module}/defaults.yaml"))

    codebuild_projects                          =   { for project_name, project_config in { "${var.project_name}" = local.defaults["build_service_template"] } : 
                                                            project_name => merge(project_config ,  
                                                                        {"environment": {"env_vars":   concat( coalesce(project_config.environment.env_vars, []), [
                                                                                                                            { "name"    :   "region",                 "value"   :   var.aws_region },
                                                                                                                            { "name"    :   "environment",            "value"   :   var.environment },
                                                                                                                            { "name"    :   "namespace",              "value"   :   var.namespace },
                                                                                                                            { "name"    :   "project",                "value"   :   var.project },
                                                                                                                            { "name"    :   "account_id",             "value"   :   var.account_id } ,
                                                                                                                            { "name"    :   "location",               "value"   :   "${var.source_code_provider.base_url}/${local.repository_location}"}
                                                                                                            ] , var.env_vars )
                                                                        },
                                                                        "service_role" : coalesce(var.service_role , "${local.raw_project_name}_service_role") 
                                                                        })
                                                            
                                                    }

    codebuild_projects_flatten                  =   flatten([
                                                                for name , config in  local.codebuild_projects: [
                                                                    for operation in toset(["build", "deploy"]): 
                                                                    { name: "${name}_${operation}" , config: {
                                                                        name            : "${name}_${operation}",
                                                                        original_name   : name ,
                                                                        service_role    : config.service_role ,
                                                                        security_groups : config.security_groups ,
                                                                        environment     : config.environment ,
                                                                        artifacts       : "CODEPIPELINE" ,
                                                                        source :  {
                                                                            type            : "CODEPIPELINE" ,
                                                                            buildspec       : "Codebuild/${var.buildspec}_${operation}.yml"
                                                                        }
                                                                        }
                                                                    }
                                                                ]
                                                    ])
    codebuild_projects_computed                 =  { for value in local.codebuild_projects_flatten : value.name => value.config }


    codepipeline_projects                       =   { for project, config  in local.codebuild_projects: project => {
                                                        "service_role"           : config.service_role ,
                                                        "name"                   : "${replace(project, "-", "_")}",
                                                        "stages_template"        : "project_build_stages" ,
                                                        "actions":               {
                                                            "ProjectSource":         {
                                                                "FullRepositoryId": local.repository_location ,
                                                                "BranchName"  : "master"
                                                            },
                                                            "Build":{
                                                                "ProjectName" : "${project}_build"
                                                            },
                                                            "Deploy":{
                                                                "ProjectName" : "${project}_deploy"
                                                            }
                                                        }
                                                    }} 

}

module "module_codebuild" {
  source = "../core-modules/module-codebuild"

  environment                   =   var.environment
  aws_region                    =   var.aws_region
  account_id                    =   var.account_id
  default_tags                  =   var.default_tags

  subnet_ids                    =   var.subnet_ids
  vpc_id                        =   var.vpc_id
  codebuild_projects            =   local.codebuild_projects_computed
}

module "module_codepipeline" {
  source = "../core-modules/module-codepipeline"

  environment                   =   var.environment
  aws_region                    =   var.aws_region
  account_id                    =   var.account_id
  default_tags                  =   var.default_tags
  
  codepipeline_projects         =   local.codepipeline_projects

  depends_on = [
      module.module_codebuild
  ]  
}