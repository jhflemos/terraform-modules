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
          },
          {
            Action    = [
             "ssm:GetParametersByPath", 
             "ssm:GetParameter"
            ],
            Effect    = "Allow",
            Resource  = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.app_name}/${var.environment}/*"
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

  }
}