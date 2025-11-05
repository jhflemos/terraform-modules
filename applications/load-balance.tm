generate_hcl "_auto_generated_load_balance.tf" {
  content {
    resource "aws_lb_target_group" "app_lb_service_tg" {
      name        = "${var.app_name}-service-tg"
      port        = 8080
      protocol    = "HTTP"
      vpc_id      = var.vpc_id
      target_type = "ip"

      health_check {
        path                = "/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200-399"
      }
    }

    resource "aws_lb_listener" "https" {
      load_balancer_arn = var.alb_arn
      port              = "443"
      protocol          = "HTTPS"
      ssl_policy        = "ELBSecurityPolicy-2016-08"
      certificate_arn   = var.aws_acm_certificate_arn

      default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app_lb_service_tg.arn
      }
    }

    resource "aws_lb_listener" "http" {
      load_balancer_arn = var.alb_arn
      port              = 80
      protocol          = "HTTP"

      default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app_lb_service_tg.arn
      }
    }

  }
}
