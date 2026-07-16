
output "output_iam_mod_service_roles" {
  value = {for key, value in aws_iam_role.infra_services_roles: key => {id = value.id, arn = value.arn}}
}

output "output_iam_users_secret_access_key" {
  sensitive = true
  value = {for key, value in aws_iam_access_key.managed_users_access_key: key => { id = value.id, secret = value.secret, status = value.status}}
}

output "output_aws_iam_user_login_profile" {
  sensitive = true
  value = {for key, value in aws_iam_user_login_profile.managed_users_login_profile: key => {id = value.id, plain_psw = value.password, encrypted_psw = value.encrypted_password}}
}