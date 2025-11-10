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

    resource "aws_codedeploy_deployment_group" "ecs_deployment_group_canary" {
      app_name               = aws_codedeploy_app.ecs_app.name
      deployment_group_name  = "${var.app_name}-${var.environment}-canary"
      service_role_arn       = aws_iam_role.codedeploy_role.arn
      deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

      ecs_service {
        service_name = aws_ecs_service.app_service.name
        cluster_name = "${var.environment}-ecs-cluster"
      }

      load_balancer_info {
        target_group_pair_info {
          target_group {
            name = aws_lb_target_group.app_lb_service_tg_blue.name
          }
          target_group {
            name = aws_lb_target_group.app_lb_service_tg_green.name
          }
          prod_traffic_route {
            listener_arns = [aws_lb_listener_rule.rule[0].arn]
          }
        }
      }

      blue_green_deployment_config {
        deployment_ready_option {
          action_on_timeout = "CONTINUE_DEPLOYMENT"
        }

        terminate_blue_instances_on_deployment_success {
          action                           = "TERMINATE"
          termination_wait_time_in_minutes = 5
        }
      }

      auto_rollback_configuration {
        enabled = true
        events  = ["DEPLOYMENT_FAILURE"]
      }

      deployment_style {
        deployment_type   = "BLUE_GREEN"
        deployment_option = "WITH_TRAFFIC_CONTROL"
      }
    }
  }
}
