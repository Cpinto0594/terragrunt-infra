locals {
    defaults                =   yamldecode(file("${path.module}/defaults.yaml"))

    vpc_id                  =   var.vpc_id
    subnet_ids              =   var.subnet_ids
    codebuild_projects      =   var.codebuild_projects

    security_group_ids      =   distinct(concat(flatten([ 
                                              for  name, config in local.codebuild_projects : [
                                                for sec_group in flatten(concat(local.defaults["codebuild_project"]["security_groups"],  coalesce( config.security_groups , [] ))) :
                                                  data.aws_security_group.cb_sec_groups[sec_group].id 
                                              ]
                                              ])))

    tags                    =   var.default_tags
}

resource "aws_codebuild_project" "code_build_projects" {
    for_each      = local.codebuild_projects
    name          = each.value.name
    description   = try(each.value.description, each.value.name)
    build_timeout = coalesce(each.value.build_timeout , local.defaults["codebuild_project"]["build_timeout"])
    service_role  = data.aws_iam_role.cb_iam_service_roles[each.value.service_role].arn

    environment {
      compute_type                = coalesce( each.value.environment.compute_type , local.defaults["codebuild_project"]["environment"]["compute_type"]  )
      image                       = coalesce( each.value.environment.image , local.defaults["codebuild_project"]["environment"]["image"] )
      type                        = coalesce( each.value.environment.type , local.defaults["codebuild_project"]["environment"]["type"] )
      privileged_mode             = coalesce( each.value.environment.privileged_mode , local.defaults["codebuild_project"]["environment"]["privileged_mode"] )

      dynamic "environment_variable" {
        for_each = { for value in coalesce(each.value.environment.env_vars, [] ) : value.name => value}
        content {
          name  = environment_variable.key
          type  = try(environment_variable.value.type, "PLAINTEXT")
          value = environment_variable.value.value
        }
      }
    }

    logs_config {
      cloudwatch_logs {
          group_name  = "/codebuild/apps/${each.value.name}" 
          stream_name = each.value.name 
          status      = "ENABLED"
      }

      dynamic "s3_logs" {
        for_each = try(each.value.logs_config.s3_logs, null) != null ? ["1"] : []
        content {
            status   = try(each.value.logs_config.s3_logs.status, "ENABLED")
            location = each.value.logs_config.s3_logs.location
        }
      }
    }

    source {
      type            = each.value.source.type
      location        = each.value.source.location
      git_clone_depth = each.value.source.type != "CODEPIPELINE" ? 1 : 0
      buildspec       = each.value.source.buildspec

    }

    artifacts {
      type = coalesce(each.value.artifacts, "NO_ARTIFACTS")
    }


    source_version = coalesce( each.value.source_version ,  local.defaults["codebuild_project"]["source_version"]  )

    vpc_config {
      vpc_id = local.vpc_id
      subnets = local.subnet_ids
      security_group_ids = local.security_group_ids
    }

    tags = merge( local.tags , {
        Name = each.key
    })
}

data "aws_security_group" "cb_sec_groups" {
  for_each  = toset(distinct(concat(flatten([
                    for cb_project, config in local.codebuild_projects : config.security_groups
                  ]))))
  name = each.value
}

data "aws_iam_role" "cb_iam_service_roles" {
  for_each  = toset(distinct([
                    for cb_project, config in local.codebuild_projects : config.service_role
                  ]))
  name = each.value
}