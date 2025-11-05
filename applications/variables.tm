generate_hcl "_auto_generated_variables.tf" {
  content {
    variable "app_name" {
      type        = string
      description = "Application name"
    }

    variable "vpc_id" {
      type        = string
      description = ""
    }

     variable "tags" {
       type        = map(string)
       default     = {}
       description = "A map of tags to add to all resources."
     }

    variable "environment" {
      type        = string
      description = "Environment which the module is being currently run in i.e. dev or prod"
    }

    variable "kms" {
      type    = any
      default = {}
    } 

    variable "alb_arn" {
      type        = string
      description = ""
    }

    variable "alb_sg_id" {
      type        = string
      description = ""
    }

    variable "private_subnets" {
      type        = list(string)
      description = "A list of private subnets"
      default     = []
    }

    variable "env_vars" {
      type = list(object({
        name  = string
        value = string
      }))
    }

    variable "ssm_parameters" {
      description = "List of SSM parameters to inject as ECS secrets"
      type = list(object({
        name = string
      }))
    }
    
  }
}