locals {

  route53_zones   = coalesce(var.route53_zones, {})
  route53_records = coalesce(var.route53_zone_records, {})

  # Only zones with a vpc name set (private hosted zones)
  private_zones = {
    for name, config in coalesce(local.route53_zones, {}) :
    name => config if try(config.vpc, null) != null
  }

  tags = var.default_tags
}

data "aws_vpc" "zones_vpc" {
  for_each = local.private_zones

  tags = {
    Name = each.value.vpc
  }
}

resource "aws_route53_zone" "zones" {
  for_each = local.route53_zones

  name          = each.key
  comment       = try(each.value.comment, null)
  force_destroy = try(each.value.force_destroy, false)

  dynamic "vpc" {
    for_each = try(each.value.vpc, null) != null ? [each.key] : []
    content {
      vpc_id = data.aws_vpc.zones_vpc[vpc.value].id
    }
  }

  tags = merge(var.default_tags, {
    Name = each.key
  })

  depends_on = [data.aws_vpc.zones_vpc]
}

# for prod records high ttl is recommended since the NS records are not expected to change frequently ( 86400 - 172800 / 1 - 2 days ).
# For dev and test environments, a lower TTL can be used to allow for quicker updates if needed.
resource "aws_route53_record" "records" {
  for_each = local.route53_records

  zone_id = aws_route53_zone.zones[each.value.zone_name].zone_id
  name    = each.key
  type    = each.value.type
  ttl     = each.value.ttl

  records = coalesce(
    each.value.records,
    each.value.records_from_zone != null ? aws_route53_zone.zones[each.value.records_from_zone].name_servers : null
  )

  depends_on = [aws_route53_zone.zones]
}

