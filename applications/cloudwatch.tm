generate_hcl "_auto_generated_cloudwatch.tf" {
  content {
    resource "aws_cloudwatch_log_group" "app_logs" {
      name              = "/ecs/${var.environment}/app/${var.app_name}"
      retention_in_days = 30
      kms_key_id        = aws_kms_key.app_kms_key.arn

      tags = {
        Name        = "/ecs/${var.environment}/app/${var.app_name}"
        Application = var.app_name
      }
    }
  }
}
