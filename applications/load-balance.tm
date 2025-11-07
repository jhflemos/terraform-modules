generate_hcl "_auto_generated_load_balance.tf" {
  content {
    locals {
      alb_defaults = {
        health_check = {
          path                = "/"
          interval            = 30
          timeout             = 5
          healthy_threshold   = 2
          unhealthy_threshold = 2
          matcher             = "200-399"
        }
      }

      alb = merge(local.alb_defaults, var.alb)
    }

    resource "aws_lb_target_group" "app_lb_service_tg" {
      name        = "${var.app_name}-${var.environment}-service-tg"
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
        Name        = "${var.app_name}-${var.environment}-service-tg"
        Application = var.app_name
      }
    }

    resource "aws_lb_listener" "https" {
      load_balancer_arn = local.alb.alb_arn
      port              = "443"
      protocol          = "HTTPS"
      ssl_policy        = "ELBSecurityPolicy-2016-08"
      certificate_arn   = local.alb.aws_acm_certificate_arn

      default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app_lb_service_tg.arn
      }
      
      tags = {
        Name        = "${var.app_name}-${var.environment}-lb-listener-https"
        Application = var.app_name
      }
    }

    resource "aws_lb_listener" "http" {
      load_balancer_arn = local.alb.alb_arn
      port              = 80
      protocol          = "HTTP"

      default_action {
        type = "redirect"

        redirect {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }

      tags = {
        Name        = "${var.app_name}-${var.environment}-lb-listener-http"
        Application = var.app_name
      }
    }

    resource "aws_lb_listener_rule" "rules" {
      count        = try(length(local.alb.listener.condition), 0) > 0 ? 1 : 0
      listener_arn = aws_lb_listener.https.arn
      priority     = 50

      action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app_lb_service_tg.arn
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

  }
}
