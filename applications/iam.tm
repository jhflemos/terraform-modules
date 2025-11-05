generate_hcl "_auto_generated_iam.tf" {
  content {
    resource "aws_iam_role" "ecs_task_execution" {
      name = "ecsTaskExecutionRole"

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
    }

    resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
      role       = aws_iam_role.ecs_task_execution.name
      policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    }

    resource "aws_iam_role" "ecs_task" {
      name = "ecsTaskAppRole"

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
    }

    resource "aws_iam_policy" "ecs_ssm_policy" {
      name        = "${var.app_name}-${var.environment}-ecs-ssm-policy"
      description = "Allow ECS task to read parameters from SSM Parameter Store"

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
            Resource = "arn:aws:ssm:us-east-1:123456789012:parameter/app/${var.app_name}/${var.environment}*"
          }
        ]
      })
    }

    resource "aws_iam_role_policy_attachment" "ecs_task_ssm_attach" {
      role       = aws_iam_role.ecs_task.name
      policy_arn = aws_iam_policy.ecs_ssm_policy.arn
    }

  }
}
