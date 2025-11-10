generate_hcl "_auto_generated_api-gateway.tf" {
  content {
    resource "aws_apigatewayv2_api" "api" {
      count = var.api ? 1 : 0

      name          = "${var.app_name}-${var.environment}"
      protocol_type = "HTTP"
    }

    resource "aws_apigatewayv2_vpc_link" "vpc_link" {
      count = var.api ? 1 : 0

      name = "${var.app_name}-${var.environment}-vpc-link"
      subnet_ids = var.private_subnets
      security_group_ids = [aws_security_group.vpc_link_sg.id]
    }

    resource "aws_apigatewayv2_integration" "alb_integration" {
      count = var.api ? 1 : 0
      api_id = aws_apigatewayv2_api.api[0].id
      integration_type = "HTTP_PROXY"
      integration_uri  = var.alb.listener_arn
      integration_method = "ANY"
      connection_type = "VPC_LINK"
      connection_id   = aws_apigatewayv2_vpc_link.vpc_link[0].id
      payload_format_version = "1.0"
    }

    resource "aws_apigatewayv2_route" "route" {
      count = var.api ? 1 : 0

      api_id     = aws_apigatewayv2_api.api[0].id
      route_key  = "GET /orders"
      target     = "integrations/${aws_apigatewayv2_integration.alb_integration[0].id}"
    }

    resource "aws_apigatewayv2_route" "proxy_route" {
      count = var.api ? 1 : 0
      
      api_id     = aws_apigatewayv2_api.api[0].id
      route_key  = "GET /orders/{proxy+}"
      target     = "integrations/${aws_apigatewayv2_integration.alb_integration[0].id}"
    }

    resource "aws_apigatewayv2_deployment" "api_deployment" {
      count = var.api ? 1 : 0

      api_id = aws_apigatewayv2_api.api[0].id

      depends_on = [
        aws_apigatewayv2_route.route,
        aws_apigatewayv2_route.proxy_route
      ]
    }

    resource "aws_apigatewayv2_stage" "stage" {
      count = var.api ? 1 : 0

      api_id        = aws_apigatewayv2_api.api[0].id
      name          = var.environment
      deployment_id = aws_apigatewayv2_deployment.api_deployment[0].id
      auto_deploy   = false
    }

    resource "aws_apigatewayv2_api_key" "api_key" {
      name    = "${var.app_name}-${var.environment}-key"
      enabled = true
    }

    # -----------------------
    # Usage Plan
    # -----------------------
    resource "aws_apigatewayv2_usage_plan" "usage_plan" {
      name = "${var.app_name}-${var.environment}-usage-plan"
    }

    # -----------------------
    # Usage Plan Key (connects the API key to the plan)
    # -----------------------
    resource "aws_apigatewayv2_usage_plan_key" "plan_key" {
      key_id        = aws_apigatewayv2_api_key.api_key.id
      key_type      = "API_KEY"
      usage_plan_id = aws_apigatewayv2_usage_plan.usage_plan.id
    }

    # -----------------------
    # API Gateway Route Settings — Require API key
    # -----------------------
    resource "aws_apigatewayv2_route_settings" "orders_route_settings" {
      api_id = aws_apigatewayv2_api.api[0].id
      stage_name = aws_apigatewayv2_stage.prod.name

      route_key = aws_apigatewayv2_route.route[0].route_key

      throttling_burst_limit = 100
      throttling_rate_limit  = 50
    }
  }
}
