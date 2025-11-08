generate_hcl "_auto_generated_data.tf" {
  content {
    data "aws_caller_identity" "current" {}

    data "aws_region" "current" {}
  }
}
