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


variable insecure_params {
  type = map(object({
    type  =  optional(string)
    value = string
  }))
  default = {}
}

variable secure_params {
  type = map(object({
    type  =  optional(string)
    value = string
  }))
  default = {}
}

