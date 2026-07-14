output "output_codepipeline_mod_cp_projects" {
    value   = { for key, value in aws_codepipeline.iac_codepipeline_projects: key => {arn: value.arn, id: value.id} }
}

