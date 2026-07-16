locals {

  security_groups = var.security_groups

  trafic_rules = {
    for value in local.security_groups : value.name => value
  }

  tags = var.default_tags
}

resource "aws_security_group" "app_security_groups" {
  for_each    = { for value in local.security_groups : value.name => value }
  name        = each.key
  description = each.value.description
  vpc_id      = var.app_vpc_id


  dynamic "ingress" {
    for_each = [for ingress_data in try(local.trafic_rules[each.key].ingress, []) : ingress_data]
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
    for_each = [for egress_data in try(local.trafic_rules[each.key].egress, []) : egress_data]
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      description      = egress.value.description
    }
  }

  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  for_each = { for key, value in flatten([
    for key, value in local.trafic_rules :
    [for idx, rule in value.ingress : {
      key          = key
      idx          = idx
      ingress_rule = rule
    }]
  ]) : "${value.key}_${value.idx}" => value }

  security_group_id = aws_security_group.app_security_groups[each.value.key].id
  cidr_ipv4         = each.value.ingress_rule.cidr_blocks[0]
  from_port         = each.value.ingress_rule.from_port
  ip_protocol       = each.value.ingress_rule.protocol
  to_port           = each.value.ingress_rule.to_port

  depends_on = [aws_security_group.app_security_groups]

  tags = merge(local.tags, {
    Name = "allow_tls_ipv4_${each.value.key}"
  })
}
