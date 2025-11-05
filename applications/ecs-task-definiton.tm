generate_hcl "_auto_generated_ecs_task_defintion.tf" {
  content {
    resource "aws_ecs_task_definition" "app" {
      family                   = "${var.app_name}"
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu                      = "256"
      memory                   = "512"
      execution_role_arn       = aws_iam_role.ecs_task_execution.arn
      task_role_arn            = aws_iam_role.ecs_task.arn

      container_definitions = jsonencode([
        {
          name      = "app"
          image     = "${aws_ecr_repository.app_ecr_repo.repository_url}:latest"
          essential = true
          portMappings = [
            { containerPort = 8080, hostPort = 8080, protocol = "tcp" }
          ]
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = aws_cloudwatch_log_group.app_logs.name
              awslogs-region        = data.aws_region.current.region
              awslogs-stream-prefix = "ecs"
            }
          }
        }
      ])
    }
  }
}
