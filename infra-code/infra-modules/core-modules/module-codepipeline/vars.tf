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

variable "codepipeline_projects" {
  type    = map(object({
    service_role    = string
    name            = string,
    stages_template = string ,
    actions         = map(map(any))
  }))
}