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

variable "vpc_cidr"{
  type = string
}

variable "private_route_cidrs"{
  type = list(string)
}

variable "public_route_cidrs"{
  type = list(string)
}

variable "public_subnets_cidrs"{
  type = list(string)
}
variable "private_subnets_cidrs"{
  type = list(string)
}
variable "public_subnets_available_zones"{
  type = list(string)
}
variable "private_subnets_available_zones"{
  type = list(string)
}
variable "public_route_tables"{
  type = list(string)
}
variable "private_route_tables"{
  type = list(string)
}