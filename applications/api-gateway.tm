generate_hcl "_auto_generated_api-gateway.tf" {
  content {
    resource "aws_apigatewayv2_api" "api" {
      count = var.api ? 1 : 0

      name          = "${var.app_name}-${var.environment}"
      protocol_type = "HTTP"
    }

    resource "aws_apigatewayv2_integration" "alb_integration" {
      count = var.api ? 1 : 0

      api_id                 = aws_apigatewayv2_api.api[0].id
      integration_type       = "HTTP_PROXY"
      integration_uri        = var.alb.alb_dns_name
      payload_format_version = "1.0"
    }

    resource "aws_apigatewayv2_route" "route" {
      count = var.api ? 1 : 0

      api_id     = aws_apigatewayv2_api.api[0].id
      route_key  = "ANY /orders"
      target     = "integrations/${aws_apigatewayv2_integration.alb_integration[0].id}"
    }

    resource "aws_apigatewayv2_route" "proxy_route" {
      count = var.api ? 1 : 0
      
      api_id     = aws_apigatewayv2_api.api[0].id
      route_key  = "ANY /orders/{proxy+}"
      target     = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
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
      auto_deploy   = true
    }
  }
}
