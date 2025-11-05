generate_hcl "_auto_generated_iam.tf" {
  content {
    resource "aws_iam_role" "ecs_task_execution" {
      name = "${var.app_name}-${var.environment}-ecsTaskExecutionRole"

      assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Action    = "sts:AssumeRole",
            Effect    = "Allow",
            Principal = { Service = "ecs-tasks.amazonaws.com" }
          }
        ]
      })

      tags = {
        Name        = "${var.app_name}-${var.environment}-ecsTaskExecutionRole"
        Application = var.app_name
      }
    }

    resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
      role       = aws_iam_role.ecs_task_execution.name
      policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    }

    resource "aws_iam_role" "ecs_task" {
      name = "${var.app_name}-${var.environment}-ecsTaskAppRole"

      assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Action    = "sts:AssumeRole",
            Effect    = "Allow",
            Principal = { Service = "ecs-tasks.amazonaws.com" }
          }
        ]
      })

      tags = {
        Name        = "${var.app_name}-${var.environment}-ecsTaskAppRole"
        Application = var.app_name
      }
    }

    resource "aws_iam_policy" "ecs_custom_policy" {
      name        = "${var.app_name}-${var.environment}-ecs-custom-policy"
      description = "Custom policy for ecs"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "ssm:GetParameters",
              "ssm:GetParameter",
              "ssm:GetParametersByPath"
            ]
            Resource = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/app/${var.app_name}/${var.environment}*"
          },
          {
            Effect = "Allow"
            Action = [
              "kms:*"
            ]
            Resource = aws_kms_key.app_kms_key.arn
          }
        ]
      })

      tags = {
        Name        = "${var.app_name}-${var.environment}-ecs-custom-policy"
        Application = var.app_name
      }
    }

    resource "aws_iam_role_policy_attachment" "ecs_task_ssm_attach" {
      role       = aws_iam_role.ecs_task.name
      policy_arn = aws_iam_policy.ecs_custom_policy.arn
    }

    resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm_attach" {
      role       = aws_iam_role.ecs_task_execution.name
      policy_arn = aws_iam_policy.ecs_custom_policy.arn
    }
  }
}
