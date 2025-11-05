generate_hcl "_auto_generated_security_group.tf" {
  content {
    resource "aws_security_group" "ecs_sg" {
      name        = "${var.environment}-ecs-sg"
      description = "Allow traffic from ALB"
      vpc_id      = var.vpc_id

      ingress {
        from_port       = 8080
        to_port         = 8080
        protocol        = "tcp"
        security_groups = [var.alb_sg_id]
      }

      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }

      tags = { 
        Name        = "${var.environment}-ecs-sg" 
        Environment = var.environment
      }
    }
  }
}
