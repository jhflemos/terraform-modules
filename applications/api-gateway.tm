generate_hcl "_auto_generated_api_gateway.tf" {

  content {
    resource "aws_apigatewayv2_api" "api_gateway" {
      name          = "${var.app_name}-${var.environment}-api-gateway"
      protocol_type = "HTTP"
    }

    resource "aws_apigatewayv2_integration" "alb_integration" {
      api_id           = aws_apigatewayv2_api.api_gateway.id
      integration_type = "HTTP_PROXY"
      integration_uri  = var.alb.listener_arn
      payload_format_version = "1.0"
    }

    resource "aws_apigatewayv2_route" "api_route" {
      api_id    = aws_apigatewayv2_api.api_gateway.id
      route_key = "ANY /api/{proxy+}"
      target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
    }

    resource "aws_apigatewayv2_stage" "api_stage" {
      api_id      = aws_apigatewayv2_api.api_gateway.id
      name        = "$default"
      auto_deploy = true
    }
  }
}
