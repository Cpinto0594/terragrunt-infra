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


variable "managed_infra_policies" {
  type =  map(object({
            policy = object({
                Version           = string 
                Statement         = list(object({
                  Effect          = string
                  Principal       = optional(object({
                      Service     = optional(list(string))
                  }))
                  Action          = list(string)
                  Resource        = optional(list(string))
                }))
            })
          }))
}

variable "managed_infra_roles" {
  type =  map(object({
            path                  =  optional(string)
            managed_policies_arn  =  optional(list(string))
            managed_policies      =  optional(list(string))
            assume_role_policy    =  object({
                Version                 = string 
                Statement               = list(object({
                  Effect                = string
                  Principal             = optional(object({
                      Service           = optional(list(string))
                  }))      
                  Action                = list(string)
                }))
            })
          }))
}
