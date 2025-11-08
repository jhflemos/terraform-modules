generate_hcl "_auto_generated_ecs.tf" {
  content {
    resource "aws_ecs_task_definition" "app" {
      family                   = "${var.app_name}-${var.environment}-task-definition"
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
          environment = var.env_vars
          secrets = [
            for param in var.ssm_parameters : {
              name      = param.name
              valueFrom = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/app/${var.app_name}/${var.environment}/${param.name}"
            }
          ]
        }
      ])

      tags = {
        Name        = "${var.app_name}-${var.environment}-task-definition"
        Application = var.app_name
      }
    }

    resource "aws_ecs_service" "app_service" {
      name             = "${var.app_name}-${var.environment}-service"
      cluster          = "${var.environment}-ecs-cluster"
      task_definition  = aws_ecs_task_definition.app.arn
      launch_type      = "FARGATE"
      desired_count    = 3
      platform_version = "LATEST"

      network_configuration {
        subnets         = var.private_subnets
        assign_public_ip = false
        security_groups = [aws_security_group.ecs_sg.id]
      }

      load_balancer {
        target_group_arn = aws_lb_target_group.app_lb_service_tg_blue.arn
        container_name   = "app"
        container_port   = 8080
      }

      deployment_controller {
        type = "CODE_DEPLOY"
      }

      deployment_minimum_healthy_percent = 50
      deployment_maximum_percent         = 200

      depends_on = [
        aws_lb_target_group.app_lb_service_tg_blue,
        aws_lb_target_group.app_lb_service_tg_green,
        aws_ssm_parameter.ssm_parameter
      ]

      lifecycle {
        ignore_changes = [
          platform_version,
          load_balancer,
          task_definition,
          desired_count,
        ]
      }

      tags = {
        Name        = "${var.app_name}-${var.environment}-service"
        Application = var.app_name
      }
    }

    resource "aws_appautoscaling_target" "ecs_target" {
      max_capacity       = 5
      min_capacity       = 3
      resource_id        = "service/${var.environment}-ecs-cluster/${var.app_name}-${var.environment}-service"
      scalable_dimension = "ecs:service:DesiredCount"
      service_namespace  = "ecs"

      tags = {
        Name        = "${var.app_name}-${var.environment}-autoscaling-target"
        Application = var.app_name
      }

      depends_on = [
        aws_ecs_service.app_service
      ]
    }

    resource "aws_appautoscaling_policy" "cpu_scale" {
      name               = "${var.app_name}-${var.environment}-cpu-scaling-policy"
      policy_type        = "TargetTrackingScaling"
      resource_id        = aws_appautoscaling_target.ecs_target.resource_id
      scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
      service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

      target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value       = 60
        scale_in_cooldown  = 120
        scale_out_cooldown = 60
      }
    }

    resource "aws_appautoscaling_policy" "memory_scale" {
      name               = "${var.app_name}-${var.environment}-memory-scaling-policy"
      policy_type        = "TargetTrackingScaling"
      resource_id        = aws_appautoscaling_target.ecs_target.resource_id
      scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
      service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

      target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
        target_value       = 70  # scale if avg memory > 70%
        scale_in_cooldown  = 120
        scale_out_cooldown = 60
      }
    }
  }
}
