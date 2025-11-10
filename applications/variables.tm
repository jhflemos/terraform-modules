generate_hcl "_auto_generated_variables.tf" {
  content {
    variable "app_name" {
      type        = string
      description = "Application name"
    }

    variable "vpc_id" {
      type        = string
      description = "VPC id used to create the application resources"
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

    variable "kms" {
      type = object({
        deletion_window_in_days = number
        enable_key_rotation     = bool
        is_enabled              = bool
        key_usage               = string
        multi_region            = bool
      })
      default = {
       deletion_window_in_days = 7
       enable_key_rotation     = true
       is_enabled              = true
       key_usage               = "ENCRYPT_DECRYPT"
       multi_region            = false
     }

      description = "KMS key used to encrypt and decrypt data"
    }

    variable "elb" {
      type        = any
      description = "ELB configuration with listener and health check settings"
    }

    variable "api" {
      type        = any
      description = "API configuration with paths to be create on API Gateway"
      default     = {}
    }

    variable "private_subnets" {
      type        = list(string)
      description = "A list of VPC private subnets"
      default     = []
    }

    variable "env_vars" {
      type = list(object({
        name  = string
        value = string
      }))

      description = "List of environment variables to inject into the container."
      default     = []
    }

    variable "ssm_parameters" {
      type = list(object({
        name = string
      }))

      description = "List of SSM parameters to inject as ECS secrets"
      default     = []
    }
  }
}
