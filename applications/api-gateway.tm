generate_hcl "_auto_generated_api_gateway.tf" {
  content {
    resource "aws_apigatewayv2_api" "api_gateway" {
      count = var.api_gateway ? 1 : 0

      name          = "${var.app_name}-${var.environment}-api-gateway"
      protocol_type = "HTTP"
    }

    resource "aws_apigatewayv2_integration" "alb_integration" {
      count = var.api_gateway ? 1 : 0

      api_id                 = aws_apigatewayv2_api.api_gateway[0].id
      integration_type       = "HTTP"
      integration_uri        = "https://${var.alb.alb_dns_name}/api"
      integration_method     = "ANY"
      payload_format_version = "1.0"
    }

    resource "aws_apigatewayv2_route" "api_route" {
      count = var.api_gateway ? 1 : 0

      api_id    = aws_apigatewayv2_api.api_gateway[0].id
      route_key = "ANY /api/{proxy+}"
      target    = "integrations/${aws_apigatewayv2_integration.alb_integration[0].id}"
    }

    resource "aws_apigatewayv2_stage" "api_stage" {
      count = var.api_gateway ? 1 : 0

      api_id      = aws_apigatewayv2_api.api_gateway[0].id
      name        = "$default"
      auto_deploy = true
    }
  }
}
