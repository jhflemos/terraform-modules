generate_hcl "_auto_generated_ecs_task_defintion.tf" {
  content {
    #resource "aws_ecs_task_definition" "app" {
    #  family                   = "application-1"
    #  network_mode             = "awsvpc"
    #  requires_compatibilities = ["FARGATE"]
    #  cpu                      = "256"
    #  memory                   = "512"
    #  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
    #
    #  container_definitions = jsonencode([
    #    {
    #      name      = "app"
    #      image     = "nginx:latest"
    #      essential = true
    #      portMappings = [
    #        { containerPort = 80, hostPort = 80, protocol = "tcp" }
    #      ]
    #    }
    #  ])
    #}
  }
}
