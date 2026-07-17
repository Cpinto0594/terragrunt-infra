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

  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress" {
  for_each = { for key, value in flatten([
    for key, value in local.trafic_rules :
    [for idx, rule in value.ingress : {
      key          = key
      idx          = idx
      ingress_rule = rule
    }]]) :
    join("_", [
      value.key,
      value.idx,
      value.ingress_rule.protocol == "-1" ? "ALL" : value.ingress_rule.protocol,
      coalesce(value.ingress_rule.from_port, "ALL")
  ]) => value }

  security_group_id = aws_security_group.app_security_groups[each.value.key].id
  cidr_ipv4         = try(each.value.ingress_rule.cidr_blocks[0], null)
  cidr_ipv6         = try(each.value.ingress_rule.ipv6_cidr_blocks[0], null)
  from_port         = coalesce(each.value.ingress_rule.from_port, 0) > 0 ? each.value.ingress_rule.from_port : null
  to_port           = coalesce(each.value.ingress_rule.to_port, 0) > 0 ? each.value.ingress_rule.to_port : null
  ip_protocol       = coalesce(each.value.ingress_rule.protocol, "-1")
  description       = each.value.ingress_rule.description

  depends_on = [aws_security_group.app_security_groups]

  tags = merge(local.tags, {
    Name = "ingress_${each.key}"
  })
}

resource "aws_vpc_security_group_egress_rule" "allow_egress" {
  for_each = { for key, value in flatten([
    for key, value in local.trafic_rules :
    [for idx, rule in value.egress : {
      key         = key
      idx         = idx
      egress_rule = rule
    }]]) :
    join("_", [
      value.key,
      value.idx,
      value.egress_rule.protocol == "-1" ? "ALL" : value.egress_rule.protocol,
      coalesce(value.egress_rule.from_port, "ALL")
  ]) => value }

  security_group_id = aws_security_group.app_security_groups[each.value.key].id
  cidr_ipv4         = try(each.value.egress_rule.cidr_blocks[0], null)
  cidr_ipv6         = try(each.value.egress_rule.ipv6_cidr_blocks[0], null)
  from_port         = coalesce(each.value.egress_rule.from_port, 0) > 0 ? each.value.egress_rule.from_port : null
  to_port           = coalesce(each.value.egress_rule.to_port, 0) > 0 ? each.value.egress_rule.to_port : null
  ip_protocol       = coalesce(each.value.egress_rule.protocol, "-1")
  description       = each.value.egress_rule.description

  depends_on = [aws_security_group.app_security_groups]

  tags = merge(local.tags, {
    Name = "egress_${each.key}"
  })
}
