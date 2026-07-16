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
  description = "Rds Clusters - engine"
  type        = string
}

variable "cluster_identifier" {
  description = "Rds Clusters - cluster_identifier"
  type        = string
}

variable "port" {
  description = "Rds Clusters - port"
  type        = number
}

variable "availability_zones" {
  description = "Rds Clusters - availability_zones"
  type        = list(string)
}

variable "cluster_database_name" {
  description = "Rds Clusters - cluster_database_name"
  type        =  string
}

variable "master_username" {
  description = "Rds Clusters - master_username"
  type        =  string
}

variable "master_password" {
  description = "Rds Clusters - master_password"
  type        =  string
}


variable "engine_version" {
  default     = ""
  description = "Rds Clusters - engine_version"
  type        =  string
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Rds Clusters - enabled_cloudwatch_logs_exports"
  type        =  list(string)
}

variable "vpc_security_group_ids" {
  description = "Rds Clusters - vpc_security_group_ids"
  type        =  list(string)
}



variable "r53_domain_name" {
  description = "Rds Clusters - r53_domain_name"
  type        =  string
}


variable "route_53_record_prefix" {
  default     = ""
  description = "Rds Clusters - route_53_record_prefix"
  type        =  string
}