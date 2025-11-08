variable "aws_region" {
  type        = string
  description = "AWS region where resources will be created."
  default     = "eu-west-1"
}

variable "name" {
  type        = string
  description = "Name prefix for all VPC resources."
}

 variable "tags" {
   type        = map(string)
   description = "A map of tags to add to all resources."
   default     = {}
 }

variable "environment" {
  type        = string
  description = "Environment which the module is being currently run in i.e. dev or prod"
}

variable "public_subnets" {
  description = "List of public subnets (CIDR and Availability Zone)."
  type = list(object({
    cidr_block         = string
    availability_zone  = string
  }))
}

variable "private_subnets" {
  description = "List of private subnets (CIDR and Availability Zone)."
  type = list(object({
    cidr_block         = string
    availability_zone  = string
  }))
}
