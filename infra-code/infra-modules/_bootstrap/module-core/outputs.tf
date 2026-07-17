
########## OUTPUTS
#MODULE VPC
output "output_vpc_mod_app_vpc_id" {
  value = module.module_vpc.output_vpc_mod_app_vpc_id
}

output "output_vpc_mod_private_subnets" {
  value = module.module_vpc.output_vpc_mod_private_subnets
}

output "output_vpc_mod_public_subnets" {
  value = module.module_vpc.output_vpc_mod_public_subnets
}

#Module security Groups
output "output_sg_mod_security_groups" {
  value = module.module_security_groups.output_sg_mod_security_groups
}

#MODULE IAM
output "output_iam_mod_service_roles" {
  value = module.module_iam.output_iam_mod_service_roles
}
output "output_iam_mod_users" {
  value = module.module_iam.output_iam_mod_users
}
output "output_iam_mod_user_policies" {
  value = module.module_iam.output_iam_mod_user_policies
}
output "output_iam_mod_service_roles_policies" {
  value = module.module_iam.output_iam_mod_service_roles_policies
}