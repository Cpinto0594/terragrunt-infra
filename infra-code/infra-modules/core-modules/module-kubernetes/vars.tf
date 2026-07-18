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

variable "vpc_id" {
  description = "VPC for code build projects"
  type        = string
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}


variable "cluster_name" {
  type = string
}


variable "role_arn" {
  nullable = true
  default  = null
  type     = string
}

variable "cluster_security_groups" {
  nullable = true
  default  = null
  type     = list(string)
}

variable "logs_retention_days" {
  nullable = true
  default  = 30
  type     = number
}

variable "cluster_version" {
  nullable = true
  default  = null
  type     = string
}

variable "enabled_cluster_log_types" {
  nullable = true
  default  = null
  type     = list(string)
}


variable "kube_node_groups" {
  type = list(object({
    node_group_role = optional(string)
    instance_types  = optional(list(string))
    ami_type        = optional(string)
    disk_size       = optional(number)
    capacity_type   = optional(string)
    scaling_config = optional(object({
      desired_size = number
      max_size     = number
      min_size     = number
    })),
    update_config = optional(object({
      max_unavailable = number
    }))
  }))
}


variable "cluster_addons" {
  type = list(object({
    name                 = string
    version              = optional(string)
    service_account_arn  = optional(string)
    service_account_name = optional(string)
  }))
  default = []
}

variable "oidc_enabled" {
  type    = bool
  default = false
}

variable "authentication_mode" {
  type    = string
  default = "API"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  type    = bool
  default = true
}

variable "authentication_admin_role_arns" {
  type = map(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), ["view"])
    type              = optional(string, "STANDARD")
  }))
  default = {}
}
variable "authentication_access_policy_associations" {
  type = map(object({
    principal_arn = string
    policy_arn    = string
    type          = optional(string, "cluster")
  }))
  default = {}
}
