
output "output_iam_mod_service_roles" {
  value = {for key, value in aws_iam_role.infra_services_roles: key => {id = value.id, arn = value.arn}}
}

