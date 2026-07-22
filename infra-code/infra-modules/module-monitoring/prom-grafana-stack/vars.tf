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

variable  "dns_domain" {
  type = string
}

variable  "master_domain" {
  type = string
}


variable  "kube_cluster_name" {
  type = string
}