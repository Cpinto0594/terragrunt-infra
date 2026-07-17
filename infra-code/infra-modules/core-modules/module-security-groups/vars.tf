variable "environment" {
  type        = string
  description = "Name of the environment/stack"
}

variable "aws_region" {
  type    = string
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

variable "app_vpc_id" {
  description = "VPC id"
  type        = string
}

variable "security_groups" {
  type = list(object({
    name            = string
    description     =  optional(string)
    ingress         = optional(list(object({
        protocol         = string
        from_port        = optional(number)
        to_port          = optional(number)
        description      = optional(string)
        cidr_blocks      = list(string)
        ipv6_cidr_blocks = optional(list(string))
    })))
    egress         = optional(list(object({
        protocol         = string
        from_port        = optional(number)
        to_port          = optional(number)
        description      = optional(string)
        cidr_blocks      = list(string)
        ipv6_cidr_blocks = optional(list(string))
    })))
  }))
}
