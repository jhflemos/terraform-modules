generate_hcl "_auto_generated_api_load_balance.tf" {
  content {
    resource "aws_lb_target_group" "app_lb_service_tg_blue" {
      name        = "${var.app_name}-${var.environment}-blue"
      port        = 8080
      protocol    = "HTTP"
      vpc_id      = var.vpc_id
      target_type = "ip"

      health_check {
        path                = local.alb.health_check.path
        interval            = local.alb.health_check.interval
        timeout             = local.alb.health_check.timeout
        healthy_threshold   = local.alb.health_check.healthy_threshold
        unhealthy_threshold = local.alb.health_check.unhealthy_threshold
        matcher             = local.alb.health_check.matcher
      }

      tags = {
        Name        = "${var.app_name}-${var.environment}-blue"
        Application = var.app_name
      }
    }

    resource "aws_lb_target_group" "app_lb_service_tg_green" {
      name        = "${var.app_name}-${var.environment}-green"
      port        = 8080
      protocol    = "HTTP"
      vpc_id      = var.vpc_id
      target_type = "ip"

      health_check {
        path                = local.alb.health_check.path
        interval            = local.alb.health_check.interval
        timeout             = local.alb.health_check.timeout
        healthy_threshold   = local.alb.health_check.healthy_threshold
        unhealthy_threshold = local.alb.health_check.unhealthy_threshold
        matcher             = local.alb.health_check.matcher
      }

      tags = {
        Name        = "${var.app_name}-${var.environment}-green"
        Application = var.app_name
      }
    }

    resource "aws_lb_listener_rule" "rules" {
      count        = try(length(local.alb.listener.condition), 0) > 0 ? 1 : 0
      listener_arn = aws_lb_listener.http.arn
      priority     = local.alb.listener.priority

      action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app_lb_service_tg_blue.arn
      }

      dynamic "condition" {
        for_each = lookup(local.alb.listener, "condition", [])
        content {
          dynamic "path_pattern" {
            for_each = lookup(condition.value, "path_pattern", null) == null ? [] : [condition.value.path_pattern]
            content {
              values = path_pattern.value.values
            }
          }

          dynamic "host_header" {
            for_each = lookup(condition.value, "host_header", null) == null ? [] : [condition.value.host_header]
            content {
              values = host_header.value.values
            }
          }
        }
      }
    }

    resource "aws_lb_listener" "http" {
      #count = var.api ? 0 : 1

      load_balancer_arn = var.elb.alb_arn
      port              = 80
      protocol          = "HTTP"

      default_action {
        type = "fixed-response"
        fixed_response {
          content_type = "text/plain"
          message_body = "No matching path"
          status_code = 404
        }
      }

      tags = {
        Name = "${var.environment}-lb-listener-https"
      }
    }

  }
}
