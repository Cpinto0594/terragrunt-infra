
output "output_sg_mod_security_groups" {
  value = {for key, value in aws_security_group.app_security_groups: key => {id = value.id, arn = value.arn}}
}

