generate_hcl "_auto_generated_kms.tf" {

  content {
    resource "aws_kms_key" "app_kms_key" {
      description             = "Application kms key for ${var.app_name} application on ${var.environment} environment"
      deletion_window_in_days = var.kms.deletion_window_in_days
      enable_key_rotation     = var.kms.enable_key_rotation
      key_usage               = var.kms.key_usage
      multi_region            = var.kms.multi_region
      is_enabled              = var.kms.is_enabled

      policy = jsonencode({
        Version = "2012-10-17"
        Id      = "ecr-kms-policy"
        Statement = [
          {
            Sid      = "EnableRootPermissions"
            Effect   = "Allow"
            Principal = {
              AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            }
            Action   = "kms:*"
            Resource = "*"
          },
          {
            Sid      = "AllowECRServiceUsage"
            Effect   = "Allow"
            Principal = {
              Service = "ecr.amazonaws.com"
            }
            Action = [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            Resource = "*"
          },
          {
            Sid      = "AllowECSServiceUsage",
            Effect   = "Allow",
            Principal = {
              Service = "ecs-tasks.amazonaws.com"
            },
            Action = [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ],
            Resource = "*"
          },
          {
            Sid      = "AllowCloudWatchLogsEncryption",
            Effect   = "Allow",
            Principal = {
              Service = "logs.eu-west-1.amazonaws.com"
            },
            Action = [
              "kms:Encrypt*",
              "kms:Decrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ],
            Resource = "*"
          }
        ]
      })

      tags = {
        Name        = "alias/app/${var.environment}/${var.app_name}"
        Application = var.app_name
      }
    }

    resource "aws_kms_alias" "app_kms_key_alias" {
      name          = "alias/app/${var.environment}/${var.app_name}"
      target_key_id = aws_kms_key.app_kms_key.id
    }
  }
}
