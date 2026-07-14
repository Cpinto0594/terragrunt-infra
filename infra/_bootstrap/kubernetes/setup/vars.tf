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

variable "kube_cluster_name" {
  type  = string
}


variable "cert_manager_email" {
  type  =  string
}

variable "r53_domain_name" {
  description = "r53_domain_name"
  type        =  string
}

variable "oidc_enabled" {
  type =  bool
  default = false
}

variable  "external_dns_role_arn" {
  default = null
  type =  string
}