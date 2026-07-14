
output "output_vpc_mod_app_vpc_id" {
  value = aws_vpc.app_vpc.id
}

output "output_vpc_mod_private_subnets" {
    value = {for key, value in aws_subnet.private_subnets: key => { id: value.id, arn = value.arn }}
}

output "output_vpc_mod_public_subnets" {
    value = {for key, value in aws_subnet.public_subnets: key => { id: value.id, arn = value.arn }}
}