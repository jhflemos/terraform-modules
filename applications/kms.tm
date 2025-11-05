generate_hcl "_auto_generated_kms.tf" {

  content {
    locals {
      kms_defaults = {
        deletion_window_in_days = 7
        enable_key_rotation     = true
        is_enabled              = true
        key_usage               = "ENCRYPT_DECRYPT"
        multi_region            = false
        enable_default_policy   = true
        key_owners              = []
        key_users               = []
        grants                  = {}
        aliases_use_name_prefix = false
        aliases                 = []
      }

      kms = merge(local.kms_defaults, var.kms)
    }

    module "kms" {
      source  = "terraform-aws-modules/kms/aws"
      version = "v3.1.1"

      description             = "Application kms key for ${var.app_name} application on ${var.environment} environment"
      deletion_window_in_days = local.kms.deletion_window_in_days
      enable_key_rotation     = local.kms.enable_key_rotation
      is_enabled              = local.kms.is_enabled
      key_usage               = local.kms.key_usage
      multi_region            = local.kms.multi_region

      # Policy
      enable_default_policy = local.kms.enable_default_policy
      key_owners            = local.kms.key_owners
      key_users             = local.kms.key_users

      grants = try(local.kms.grants, null)

      # Aliases
      aliases_use_name_prefix = local.kms.aliases_use_name_prefix
      aliases                 = local.kms.aliases

      computed_aliases = {
        app = {
          name = "app/${var.environment}/${var.app_name}" # app/prod/app-name || app/test/app-name
        }
      }

      tags = {
        Name        = var.app_name
        Environment = var.environment
      }
    }
  }
}
