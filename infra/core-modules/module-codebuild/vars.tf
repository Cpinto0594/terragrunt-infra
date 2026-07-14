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


variable "vpc_id" {
  description = "VPC for code build projects"
  type        = string
}

variable  "subnet_ids" {
  type = list(string)
}


variable "codebuild_projects" {
  type = map(object({
          name                      = string
          description               = optional(string)
          service_role              = string 
          security_groups           = optional(list(string))
          artifacts                 = optional(string) 
          build_timeout             = optional(number) 
          environment = object({
              type = optional(string)
              image = optional(string)
              compute_type = optional(string)
              privileged_mode = optional(bool)
              env_vars = optional(list(object({
                name  = string
                value = string
                type  = optional(string)
              })))
          })
          source = object({
            type      = string
            location  = optional(string)
            buildspec = optional(string)
          })
          source_version = optional(string)
          logs_config = optional(object({
            cloud_watch = optional(object({
                              group_name  = string 
                              stream_name = string
                              status      = optional(string)
                          }))
            s3_logs     = optional(object({
                              location    = string
                              status      = optional(string)
                          }))
          }))
        }
      ))
      default = {}
}