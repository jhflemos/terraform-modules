generate_hcl "_auto_generated_ecs_auto_scaling.tf" {
  content {
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