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

#Module Kubernetes
variable  "aws_vpc" {
  type = string
}

variable  "cluster_name" {
  type = string
}

variable  "role_arn" {
  nullable = true
  default = null
  type =  string
}

variable  "cluster_security_groups" {
  nullable = true
  default = null
  type = list(string)
}

variable  "logs_retention_days" {
  nullable = true
  default = 30
  type = number
}

variable  "cluster_version" {
  nullable = true
  default = null
  type = string
}

variable  "enabled_cluster_log_types" {
  nullable = true
  default = null
  type = list(string)
}

variable "kube_node_groups" {
  type  = list(any)
}


#Module Kubernates preparation
variable "kube_namespaces" {
    type  = list(string)
}

variable "kube_service_accounts" {
  type  = map(object({
    namespaces  = list(string)
    annotations  = optional(map(string))
    include_role_arn_annotation = optional(bool)
  }))
}

variable "kube_role_bindings" {
  type  = list(any)
}

variable "kube_cluster_roles" {
  type  = map(object({
    rules  = list(object({
      apiGroups = optional(list(string))
      resources = list(string)
      verbs = optional(list(string))
    }))
  }))
}

variable "cert_manager_email" {
  type  =  string
}

variable "r53_domain_name" {
  description = "r53_domain_name"
  type        =  string
}

variable "master_domain" {
  description = "master_domain"
  type        =  string
}


variable "oidc_enabled" {
  type =  bool
  default = false
}

variable "cluster_addons" {
  type =  list(object({
    name  =  string
    version = optional(string)
    service_account_arn = optional(string)
    service_account_name = optional(string)
  }))
  default = [  ]
}

variable  "external_dns_role_arn" {
  default = null
  type =  string
}