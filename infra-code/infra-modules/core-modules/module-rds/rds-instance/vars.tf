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


variable "engine" {
  default     = ""
  description = "Rds DB - engine"
  type        = string
}

variable "identifier" {
  description = "Rds DB - identifier"
  type        = string
}

variable "port" {
  description = "Rds DB - port"
  type        = number
}

variable "availability_zone" {
  description = "Rds DB - availability_zone"
  type        = string
}

variable "db_name" {
  description = "Rds DB - db_name"
  type        =  string
}

variable "username" {
  description = "Rds DB - username"
  type        =  string
}

variable "password" {
  description = "Rds DB - password"
  type        =  string
}

variable "instance_identifier" {
  description = "Rds Instance - instance_identifier"
  type        = string
}

variable "instance_class" {
  default     = ""
  description = "Rds Instance - instance_class"
  type        = string
}

variable "engine_version" {
  default     = ""
  description = "Rds DB - engine_version"
  type        =  string
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Rds DB - enabled_cloudwatch_logs_exports"
  type        =  list(string)
}

variable "vpc_security_group_ids" {
  description = "Rds DB - vpc_security_group_ids"
  type        =  list(string)
}

variable "allocated_storage" {
  description = "Rds DB - allocated_storage"
  type        =  number
  default     = 10
}

variable "r53_domain_name" {
  description = "Rds DB - r53_domain_name"
  type        =  string
}


variable "route_53_record_prefix" {
  default     = ""
  description = "Rds DB - route_53_record_prefix"
  type        =  string
}