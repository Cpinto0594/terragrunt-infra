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
  default     = {}
  description = "Default Resource tags"
  type        = map(string)
}

variable "master_domain" {
  description = "Master Domain"
  type        = string
}

## VPC module

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

## Security group module
variable "security_groups" {
  type = any
}

#Module IAM

variable "managed_infra_policies" {
  nullable = true
  default = {}
  type =  any
}

variable "managed_infra_roles" {
  nullable = true
  default = {}
  type =  any
}

variable "managed_infra_users" {
  nullable = true
  default = {}
  type =  any
}


#Module Code Build
variable "iac_core_codebuild_projects" {
  type = any
}

variable "iac_core_codepipeline_projects" {
  type    = any
}
