generate_hcl "_auto_generated_ssm.tf" {

  content {
    resource "random_string" "api_key" {
      length  = 32
      upper   = true
      lower   = true
      number  = true
      special = false
    }

    resource "aws_ssm_parameter" "ssm_parameter" {
      name        = "/app/${var.app_name}/${var.environment}/SECRET_FROM_SSM"
      description = "Example of secret from SSM"
      type        = "SecureString"
      value       = random_string.api_key.result
      key_id      = aws_kms_key.app_kms_key.arn
      overwrite   = true
    }
  }
}
