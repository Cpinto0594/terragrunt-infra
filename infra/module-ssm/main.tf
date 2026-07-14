locals {
  insecure_types = [ "String", "StringList" ]
  #Insecure params computed
  insecure_params = {
    for key, value in var.insecure_params: key => value
    if contains(local.insecure_types, coalesce( value.type, "String" ))
  }

  tags = merge(var.default_tags)

}

resource "aws_ssm_parameter" "ssm_parameters_insecure" {
  for_each = local.insecure_params
  name  = "${each.key}"
  type  =  coalesce( each.value.type , "String" )
  value = each.value.value
  tags = merge(local.tags , {
    Name        = each.key
  })
}

resource "aws_ssm_parameter" "ssm_parameters_secure" {
  for_each = var.secure_params
  name  = "${each.key}"
  type  = "SecureString"
  value = each.value.value
  tags = merge(local.tags , {
    Name        = each.key
  })
}
