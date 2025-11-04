// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "app_name" {
  description = "Application name"
  type        = string
}
variable "tags" {
  default     = {}
  description = "A map of tags to add to all resources."
  type        = map(string)
}
variable "environment" {
  description = "Environment which the module is being currently run in i.e. dev or prod"
  type        = string
}
