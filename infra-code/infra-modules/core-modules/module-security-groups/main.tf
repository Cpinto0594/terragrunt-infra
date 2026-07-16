locals {

    security_groups = var.security_groups

    trafic_rules = {
        for value in local.security_groups: value.name => value
    }

    tags = var.default_tags
}

resource "aws_security_group" "app_security_groups" {
    for_each = { for value in local.security_groups: value.name => value}
    name        = each.key
    description = each.value.description
    vpc_id      = var.app_vpc_id

    dynamic "ingress" {
        for_each = [for ingress_data in try( local.trafic_rules[each.key].ingress, [] ) : ingress_data]
        content {
            from_port        = ingress.value.from_port
            to_port          = ingress.value.to_port
            protocol         = ingress.value.protocol
            cidr_blocks      = ingress.value.cidr_blocks
            ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
            description      = ingress.value.description
        }
    }

    dynamic "egress" {
        for_each = [for egress_data in try( local.trafic_rules[each.key].egress, [] ): egress_data ]
        content {
            from_port        = egress.value.from_port
            to_port          = egress.value.to_port
            protocol         = egress.value.protocol
            cidr_blocks      = egress.value.cidr_blocks
            ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
            description      = egress.value.description
        }
    }

    tags = merge( local.tags , {
        Name = each.key
    })
}
