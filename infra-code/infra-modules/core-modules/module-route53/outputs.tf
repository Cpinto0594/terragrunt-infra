output "route53_zones" {
  value = aws_route53_zone.zones
}

output "route53_zone_records" {
  value = aws_route53_record.records
}