generate_hcl "_auto_generated_load_balance.tf" {
  content {
    locals {
      elb_defaults = {
        health_check = {
          path                = "/"
          interval            = 30
          timeout             = 5
          healthy_threshold   = 2
          unhealthy_threshold = 2
          matcher             = "200-399"
        }
      }

      elb = merge(local.elb_defaults, var.elb)
    }

    resource "aws_lb_target_group" "app_lb_service_tg_blue" {
      name        = "${var.app_name}-${var.environment}-blue"
      port        = 8080
      protocol    = "HTTP"
      vpc_id      = var.vpc_id
      target_type = "ip"

      health_check {
        path                = local.elb.health_check.path
        interval            = local.elb.health_check.interval
        timeout             = local.elb.health_check.timeout
        healthy_threshold   = local.elb.health_check.healthy_threshold
        unhealthy_threshold = local.elb.health_check.unhealthy_threshold
        matcher             = local.elb.health_check.matcher
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
        path                = local.elb.health_check.path
        interval            = local.elb.health_check.interval
        timeout             = local.elb.health_check.timeout
        healthy_threshold   = local.elb.health_check.healthy_threshold
        unhealthy_threshold = local.elb.health_check.unhealthy_threshold
        matcher             = local.elb.health_check.matcher
      }

      tags = {
        Name        = "${var.app_name}-${var.environment}-green"
        Application = var.app_name
      }
    }

    resource "aws_lb_listener_rule" "rule" {
      count        = try(length(local.elb.listener.condition), 0) > 0 ? 1 : 0
      listener_arn = tm_ternary(global.api, aws_lb_listener.api[0].arn, aws_lb_listener.app[0].arn)
      priority     = local.elb.listener.priority

      action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app_lb_service_tg_blue.arn
      }

      dynamic "condition" {
        for_each = lookup(local.elb.listener, "condition", [])
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

      lifecycle {
        ignore_changes = [
          action
        ]
      }
    }

    resource "aws_lb_listener" "api" {
      count = global.api ? 1 : 0

      load_balancer_arn = var.elb.alb_arn
      port              = 80
      protocol          = "HTTP"

      default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app_lb_service_tg_blue.arn
      }

      tags = {
        Name = "${var.environment}-lb-listener-api"
      }
    }

    resource "aws_lb_listener" "app" {
      count = global.api ? 0 : 1

      load_balancer_arn = var.elb.alb_arn
      port              = 80
      protocol          = "HTTP"

      default_action {
        type = "fixed-response"
        fixed_response {
          content_type = "text/plain"
          message_body = "No matching path"
          status_code  = 404
        }
      }

      tags = {
        Name = "${var.environment}-lb-listener-app"
      }
    }

    resource "aws_lb_target_group" "nlb_to_alb" {
      count = global.api ? 1 : 0

      name        = "${var.app_name}-${var.environment}-nlb-tg"
      port        = 80
      protocol    = "TCP"
      vpc_id      = var.vpc_id
      target_type = "alb"
    }

    resource "aws_lb_listener" "nlb_listener" {
      count = global.api ? 1 : 0

      load_balancer_arn = var.elb.nlb_arn
      port              = 80
      protocol          = "TCP"

      default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.nlb_to_alb[0].arn
      }
    }

  }
}
