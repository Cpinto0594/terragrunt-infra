output "output_codebuild_mod_cb_projects" {
    value   = { for key, value in aws_codebuild_project.code_build_projects: key => {arn: value.arn, id: value.id} }
}
