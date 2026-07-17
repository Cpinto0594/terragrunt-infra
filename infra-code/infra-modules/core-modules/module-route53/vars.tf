variable "environment" {
  type        = string
  description = "Name of the environment/stack"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "default_tags" {
  description = "Default Resource tags"
  type        = map(string)
}

variable "master_domain" {
  description = "Master Domain"
  type        = string
}

variable "route53_zones" {
  description = "Route53 Zones"
  type = map(object({
    comment : optional(string, null)
    force_destroy : optional(bool, false)
    vpc : optional(string, null)
  }))
}

variable "route53_zone_records" {
  description = "Route53 Zone Records"
  type = map(object({
    zone_name : string
    description : optional(string, null)
    type : string
    ttl : optional(number, 300)
    records : optional(list(string), [])
  }))
}
