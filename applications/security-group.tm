generate_hcl "_auto_generated_security_group.tf" {
  content {
    resource "aws_security_group" "ecs_sg" {
      name        = "${var.app_name}-${var.environment}-ecs-sg"
      description = "Allow traffic from ALB"
      vpc_id      = var.vpc_id

      ingress {
        from_port       = 8080
        to_port         = 8080
        protocol        = "tcp"
        security_groups = [var.alb.alb_sg_id]
      }

      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }

      tags = { 
        Name        = "${var.app_name}-${var.environment}-ecs-sg"
        Application = var.app_name
      }
    }

    resource "aws_security_group" "vpc_link_sg" {
      name        = "${var.app_name}-${var.environment}-api-gateway-vpc-link-sg"
      description = "Allows API Gateway VPC Link to reach private ALB"
      vpc_id      = var.vpc_id

      # Outbound to ALB on HTTP (or HTTPS)
      egress {
        description = "Allow traffic to ALB"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
      }

      tags = { 
        Name        = "${var.app_name}-${var.environment}-api-gateway-vpc-link-sg"
        Application = var.app_name
      }
    }

  }
}
