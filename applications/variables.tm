generate_hcl "_auto_generated_variables.tf" {
  content {
    variable "app_name" {
      type        = string
      description = "Application name"
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
  }
}