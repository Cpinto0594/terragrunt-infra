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

variable "ecr_repositories" {
  description = "List of repositories to be created"
  type        = list(string)
}

variable "ecr_repositories_config" {
  description = "Map with repository configs"
  type        = map(string)
  default     = {}
}