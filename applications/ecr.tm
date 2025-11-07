generate_hcl "_auto_generated_ecr.tf" {
  content {
    resource "aws_ecr_repository" "app_ecr_repo" {

      name                 = "${var.environment}-${var.app_name}"
      image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

      image_tag_mutability_exclusion_filter {
        filter      = "latest*"
        filter_type = "WILDCARD"
      }

      image_scanning_configuration {
        scan_on_push = true
      }

      encryption_configuration {
       encryption_type = "KMS"
       kms_key         = aws_kms_key.app_kms_key.arn
      }

      tags = {
        Name        = "${var.app_name}-${var.environment}"
        Application = var.app_name
      }

      force_delete = true
    }

    resource "aws_ecr_lifecycle_policy" "app_ecr_repo_lifecycle" {
      repository = aws_ecr_repository.app_ecr_repo.name

      policy = <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep last 15 images",
                "selection": {
                    "tagStatus": "tagged",
                    "tagPrefixList": ["main-"],
                    "countType": "imageCountMoreThan",
                    "countNumber": 15
                },
                "action": {
                    "type": "expire"
                }
            },
            {
                "rulePriority": 2,
                "description": "Keep last 5 images for dev environment",
                "selection": {
                    "tagStatus": "untagged",
                    "countType": "imageCountMoreThan",
                    "countNumber": 3
                },
                "action": {
                    "type": "expire"
                }
            },
            {
                "rulePriority": 3,
                "description": "Remove untagged images",
                "selection": {
                    "tagStatus": "tagged",
                    "tagPrefixList": ["dev-", "test-"],
                    "countType": "imageCountMoreThan",
                    "countNumber": 5
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
    EOF
    }
  }
}