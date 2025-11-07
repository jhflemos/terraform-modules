generate_hcl "_auto_generated_code_deploy.tf" {
  content {
    resource "aws_codedeploy_app" "ecs_app" {
      name             = "${var.app_name}-${var.environment}-codedeploy"
      compute_platform = "ECS"

      tags = {
        Name        = "${var.app_name}-${var.environment}-codedeploy"
        Application = var.app_name
      }
    }

    resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
      app_name               = aws_codedeploy_app.ecs_app.name
      deployment_group_name  = "${var.app_name}-${var.environment}-canary"
      service_role_arn       = aws_iam_role.codedeploy_role.arn
      deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

      ecs_service {
        service_name = "${var.app_name}-${var.environment}-service"
        cluster_name = "${var.environment}-ecs-cluster"
      }

      load_balancer_info {
        target_group_pair_info {
          target_groups {
            name = aws_lb_target_group.app_lb_service_tg.name
          }
          prod_traffic_route {
            listener_arn = local.alb.listener_arn
          }
        }
      }

      auto_rollback_configuration {
        enabled = true
        events  = ["DEPLOYMENT_FAILURE"]
      }
    }

    # Canary Deployment Config
    resource "aws_codedeploy_deployment_config" "canary" {
      compute_platform    = "ECS"
      deployment_config_name = "${var.app_name}-${var.environment}.Canary10Percent5Minutes"

      traffic_routing_config {
        type = "TimeBasedCanary"
        time_based_canary {
          canary_percentage = 10
          canary_interval   = 5
        }
      }
    }

    # Linear Deployment Config
    resource "aws_codedeploy_deployment_config" "linear" {
      compute_platform    = "ECS"
      deployment_config_name = "${var.app_name}-${var.environment}.Linear10Percent1Minute"

      traffic_routing_config {
        type = "TimeBasedLinear"
        time_based_linear {
          linear_percentage  = 10
          linear_interval    = 1
        }
      }
    }
  }
}
