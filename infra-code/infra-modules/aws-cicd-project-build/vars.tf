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

variable "namespace" {
  description = "Project Namespace"
  type        = string
}

variable "default_tags" {
  default     = {}
  description = "Default Resource tags"
  type        = map(string)
}


variable "vpc_id" {
  description = "VPC for code build projects"
  type        = string
}

variable  "subnet_ids" {
  type = list(string)
}


variable "project_name" {
  type        = string
}

variable "project" {
  type        = string
}

variable "buildspec" {
  type        = string
}

variable "service_role" {
  type        =  string
  default     =   ""
}

variable "location" {
  type        = string
  default     =   ""
}

variable "env_vars" {
  type        =   list(map(any))
  default     =   []
}

variable "source_code_provider" {
  type = any
}