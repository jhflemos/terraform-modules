generate_hcl "_auto_generated_load_balance.tf" {
  content {
    resource "aws_lb_target_group" "app_lb_service_tg" {
      name        = "${var.app_name}-${var.environment}-service-tg"
      port        = 8080
      protocol    = "HTTP"
      vpc_id      = var.vpc_id
      target_type = "ip"

      health_check {
        path                = var.alb.health_check.path
        interval            = var.alb.health_check.interval
        timeout             = var.alb.health_check.timeout
        healthy_threshold   = var.alb.health_check.healthy_threshold
        unhealthy_threshold = var.alb.health_check.unhealthy_threshold
        matcher             = var.alb.health_check.matcher
      }

      tags = {
        Name        = "${var.app_name}-${var.environment}-service-tg"
        Application = var.app_name
      }
    }

    resource "aws_lb_listener" "https" {
      load_balancer_arn = var.alb.alb_arn
      port              = "443"
      protocol          = "HTTPS"
      ssl_policy        = "ELBSecurityPolicy-2016-08"
      certificate_arn   = var.alb.aws_acm_certificate_arn

      default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app_lb_service_tg.arn
      }

      dynamic "condition" {
        for_each = lookup(var.alb.listener, "condition", [])

        content {
          dynamic "path_pattern" {
            for_each = lookup(condition.value, "path_pattern", null) == null ? [] : [condition.value.path_pattern]

            content {
              values = path_pattern.value.values
            }
          }
        }
      }
      
      tags = {
        Name        = "${var.app_name}-${var.environment}-lb-listener-https"
        Application = var.app_name
      }
    }

    #resource "aws_lb_listener" "http" {
    #  load_balancer_arn = var.alb_arn
    #  port              = 80
    #  protocol          = "HTTP"
#
    #  default_action { # change it to redirect to https
    #    type             = "forward"
    #    target_group_arn = aws_lb_target_group.app_lb_service_tg.arn
    #  }
#
    #  tags = {
    #    Name        = "${var.app_name}-${var.environment}-lb-listener-http"
    #    Application = var.app_name
    #  }
    #}

  }
}
