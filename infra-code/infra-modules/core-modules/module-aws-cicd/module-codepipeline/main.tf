locals {

  codepipeline_projects = var.codepipeline_projects

  iac_codepipeline_defaults = yamldecode(file("${path.module}/defaults.yaml"))
  connectionName            = "github_cs_connections"

  tags = var.default_tags
}

resource "aws_codepipeline" "iac_codepipeline_projects" {
  for_each      = local.codepipeline_projects
  name          = each.value.name
  role_arn      = data.aws_iam_role.cp_iam_sec_roles[each.value.service_role].arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifact_bucket[each.value.name].bucket
    type     = "S3"

    # encryption_key {
    #   id   = data.aws_kms_alias.s3kmskey.arn
    #   type = "KMS"
    # }
  }

  dynamic "stage" {
    for_each = local.iac_codepipeline_defaults[each.value.stages_template].stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = [for idx, action in stage.value.actions : merge(action, { index : idx })]
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          namespace        = try(action.value.namespace, null)
          version          = "1"
          input_artifacts  = try(action.value.input_artifacts, null)
          output_artifacts = try(action.value.output_artifacts, null)
          run_order        = try(action.value.run_order, action.value.index + 1)

          configuration = {
            ConnectionArn        = action.value.category == "Source" ? data.aws_codestarconnections_connection.codestart_connections.arn : null
            FullRepositoryId     = try(each.value.actions[action.value.name].FullRepositoryId, try(action.value.configuration.FullRepositoryId, null))
            BranchName           = try(each.value.actions[action.value.name].BranchName, try(action.value.configuration.BranchName, null))
            OutputArtifactFormat = try(each.value.actions[action.value.name].OutputArtifactFormat, try(action.value.configuration.OutputArtifactFormat, null))
            DetectChanges        = try(each.value.actions[action.value.name].DetectChanges, try(action.value.configuration.DetectChanges, null))
            ProjectName          = try(each.value.actions[action.value.name].ProjectName, try(action.value.configuration.ProjectName, null))
            CustomData           = try(each.value.actions[action.value.name].CustomData, try(action.value.configuration.CustomData, null))
            PrimarySource        = try(each.value.actions[action.value.name].PrimarySource, try(action.value.configuration.PrimarySource, null))
            EnvironmentVariables = try(jsonencode(each.value.actions[action.value.name].EnvironmentVariables), try(jsonencode(action.value.configuration.EnvironmentVariables), null))
          }
        }
      }
    }
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = local.iac_codepipeline_defaults.triggers_config[each.value.stages_template].source_action_name
      pull_request {
        events = ["OPEN", "UPDATED"]
        branches {
          includes = ["main", "development", "hotfix/**", "release/**", "feat/**", "fix/**", "feature/**"]
        }
      }
      push {
        branches {
          includes = ["main", "development", "hotfix/**", "release/**", "feat/**", "fix/**", "feature/**"]
        }
      }
    }
  }


  tags = merge(local.tags, {
    Name = each.value.name
  })
}

resource "aws_s3_bucket" "codepipeline_artifact_bucket" {
  for_each      = toset([for key, value in local.codepipeline_projects : value.name])
  bucket        = replace("codepipeline_s3_${each.value}", "_", "-")
  region = var.aws_region
  force_destroy = true
  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_artifact_bucket" {
  for_each = local.codepipeline_projects
  bucket   = aws_s3_bucket.codepipeline_artifact_bucket[each.value.name].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_role" "cp_iam_sec_roles" {
  for_each = toset(distinct([
    for cb_project, config in local.codepipeline_projects : config.service_role
  ]))
  name = each.value
}

data "aws_codestarconnections_connection" "codestart_connections" {
  name = local.connectionName

}
