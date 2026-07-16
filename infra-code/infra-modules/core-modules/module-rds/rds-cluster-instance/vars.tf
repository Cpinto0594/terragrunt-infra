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


variable "instance_identifier" {
  description = "Rds Cluster Instance - instance_identifier"
  type        = string
}

variable "cluster_name" {
  description = "Rds Cluster Instance - cluster_name"
  type        = string
}

variable "instance_class" {
  default     = ""
  description = "Rds Cluster Instance - instance_class"
  type        = string
}
