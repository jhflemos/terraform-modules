generate_hcl "_auto_generated_api-gateway.tf" {
  content {
    resource "aws_apigatewayv2_api" "api" {
      count = var.api ? 1 : 0

      name          = "${var.app_name}-${var.environment}"
      protocol_type = "HTTP"
    }

    resource "aws_apigatewayv2_integration" "alb_integration" {
      api_id                 = aws_apigatewayv2_api.api[0].id
      integration_type       = "HTTP_PROXY"
      integration_uri        = var.alb.alb_dns_name
      payload_format_version = "1.0"

      depends_on = [aws_apigatewayv2_api.api]
    }

    resource "aws_apigatewayv2_route" "route" {
      api_id     = aws_apigatewayv2_api.api[0].id
      route_key  = "ANY /orders"
      target     = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
      depends_on = [
       aws_apigatewayv2_api.api,
       aws_apigatewayv2_integration.alb_integration
      ]
    }

    resource "aws_apigatewayv2_route" "proxy_route" {
      api_id     = aws_apigatewayv2_api.api[0].id
      route_key  = "ANY /orders/{proxy+}"
      target     = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
      depends_on = [
       aws_apigatewayv2_api.api,
       aws_apigatewayv2_integration.alb_integration
      ]
    }

    resource "aws_apigatewayv2_deployment" "api_deployment" {
      api_id = aws_apigatewayv2_api.api[0].id

      depends_on = [
        aws_apigatewayv2_route.route,
        aws_apigatewayv2_route.proxy_route
      ]
    }

    resource "aws_apigatewayv2_stage" "stage" {
      api_id        = aws_apigatewayv2_api.api[0].id
      name          = var.enviroment
      deployment_id = aws_apigatewayv2_deployment.api_deployment.id
      auto_deploy   = true

      depends_on = [
       aws_apigatewayv2_api.api,
       aws_apigatewayv2_deployment.api_deployment
      ]
    }
  }
}
