generate_hcl "_auto_generated_ecr.tf" {
  content {
    resource "aws_ecr_repository" "app_ecr_repo" {

      name                 = "${var.environment}-${var.app_name}"
      image_tag_mutability = "MUTABLE"

      image_scanning_configuration {
        scan_on_push = true
      }

      tags = {
        Name        = var.app_name
        Environment = var.environment
      }
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
                    "tagStatus"     = "tagged",
                    "tagPrefixList" = ["main-"],
                    "countType"     = "imageCountMoreThan",
                    "countNumber"   = 15
                },
                "action": {
                    "type": "expire"
                }
            },
            {
                "rulePriority": 2,
                "description": "Keep last 5 images for dev environment",
                "selection": {
                    "tagStatus"     = "untagged",
                    "countType"     = "imageCountMoreThan",
                    "countNumber"   = 3
                },
                "action": {
                    "type": "expire"
                }
            },
            {
                "rulePriority": 3,
                "description": "Remove untagged images",
                "selection": {
                    "tagStatus"     = "tagged",
                    "tagPrefixList" = ["dev-", "test-"],
                    "countType"     = "imageCountMoreThan",
                    "countNumber"   = 5
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