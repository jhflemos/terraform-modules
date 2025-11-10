generate_hcl "_auto_generated_api-gateway.tf" {
  content {
    #resource "aws_apigatewayv2_api" "api" {
    #  count = var.api ? 1 : 0
#
    #  name          = "${var.app_name}-${var.environment}"
    #  protocol_type = "HTTP"
    #}

    resource "aws_api_gateway_rest_api" "api" {
      count = var.api ? 1 : 0

      name        = "${var.app_name}-${var.environment}"
      description = "REST API for ${var.app_name}"
      endpoint_configuration {
        types = ["PRIVATE"]
      }
    }

    #resource "aws_apigatewayv2_vpc_link" "vpc_link" {
    #  count = var.api ? 1 : 0
#
    #  name = "${var.app_name}-${var.environment}-vpc-link"
    #  subnet_ids = var.private_subnets
    #  security_group_ids = [aws_security_group.vpc_link_sg.id]
    #}

    resource "aws_api_gateway_vpc_link" "vpc_link" {
      count = var.api ? 1 : 0
      
      name        = "${var.app_name}-${var.environment}-vpc-link"
      target_arns = ["arn:aws:elasticloadbalancing:eu-west-1:748026688964:loadbalancer/app/prod-app-alb-api/ada1f94a9232134f"]  # The ALB ARN, not listener
    }

    resource "aws_api_gateway_resource" "orders" {
      count = var.api ? 1 : 0

      rest_api_id = aws_api_gateway_rest_api.api[0].id
      parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
      path_part   = "orders"
    }

    resource "aws_api_gateway_resource" "orders_proxy" {
      count = var.api ? 1 : 0

      rest_api_id = aws_api_gateway_rest_api.api[0].id
      parent_id   = aws_api_gateway_resource.orders[0].id
      path_part   = "{proxy+}"
    }

    resource "aws_api_gateway_method" "orders_method" {
      count = var.api ? 1 : 0

      rest_api_id   = aws_api_gateway_rest_api.api[0].id
      resource_id   = aws_api_gateway_resource.orders[0].id
      http_method   = "ANY"
      authorization = "NONE"
      api_key_required = true
    }

    resource "aws_api_gateway_method" "orders_proxy_method" {
      count = var.api ? 1 : 0

      rest_api_id   = aws_api_gateway_rest_api.api[0].id
      resource_id   = aws_api_gateway_resource.orders_proxy[0].id
      http_method   = "ANY"
      authorization = "NONE"
      api_key_required = true
    }

    resource "aws_api_gateway_integration" "alb_integration_orders" {
      count = var.api ? 1 : 0

      rest_api_id             = aws_api_gateway_rest_api.api[0].id
      resource_id             = aws_api_gateway_resource.orders[0].id
      http_method             = aws_api_gateway_method.orders_method[0].http_method
      integration_http_method = "ANY"
      type                    = "HTTP_PROXY"
      uri                     = "http://${var.alb.alb_dns_name}/api/orders"
      connection_type         = "VPC_LINK"
      connection_id           = aws_api_gateway_vpc_link.vpc_link[0].id
    }

    resource "aws_api_gateway_integration" "alb_integration_orders_proxy" {
      count = var.api ? 1 : 0

      rest_api_id             = aws_api_gateway_rest_api.api[0].id
      resource_id             = aws_api_gateway_resource.orders_proxy[0].id
      http_method             = aws_api_gateway_method.orders_proxy_method[0].http_method
      integration_http_method = "ANY"
      type                    = "HTTP_PROXY"
      uri                     = "http://${var.alb.alb_dns_name}/api/orders/{proxy}"
      connection_type         = "VPC_LINK"
      connection_id           = aws_api_gateway_vpc_link.vpc_link[0].id
    }
   
    resource "aws_api_gateway_deployment" "deployment" {
      count = var.api ? 1 : 0

      depends_on = [
        aws_api_gateway_integration.alb_integration_orders,
        aws_api_gateway_integration.alb_integration_orders_proxy
      ]
      rest_api_id = aws_api_gateway_rest_api.api[0].id
    }

    resource "aws_api_gateway_stage" "stage" {
      count = var.api ? 1 : 0

      deployment_id = aws_api_gateway_deployment.deployment[0].id
      rest_api_id   = aws_api_gateway_rest_api.api[0].id
      stage_name    = var.environment
    }

    resource "random_password" "api_key" {
      count = var.api ? 1 : 0

      length  = 32
      special = false
    }

    resource "aws_ssm_parameter" "api_key" {
      count = var.api ? 1 : 0

      name        = "/app/${var.app_name}/${var.environment}/api_key"
      description = "API Gateway key for ${var.app_name}"
      type        = "SecureString"
      value       = random_password.api_key[0].result
    }

    resource "aws_api_gateway_api_key" "api_key" {
      count = var.api ? 1 : 0

      name        = "${var.app_name}-${var.environment}-api-key"
      description = "API key for ${var.app_name}"
      enabled     = true
      value       = random_password.api_key[0].result
    }

    resource "aws_api_gateway_usage_plan" "usage_plan" {
      count = var.api ? 1 : 0

      name = "${var.app_name}-${var.environment}-usage-plan"

      api_stages {
        api_id = aws_api_gateway_rest_api.api[0].id
        stage  = var.environment
      }

      throttle_settings {
        burst_limit = 50
        rate_limit  = 100
      }

      quota_settings {
        limit  = 10000
        period = "MONTH"
      }
    }

    resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
      count = var.api ? 1 : 0

      key_id        = aws_api_gateway_api_key.api_key[0].id
      key_type      = "API_KEY"
      usage_plan_id = aws_api_gateway_usage_plan.usage_plan[0].id
    }

    ##############################################
    # Outputs
    ##############################################

    output "api_invoke_url" {
      value = var.api ? aws_api_gateway_stage.stage[0].invoke_url : null
    }

    output "api_key_ssm_path" {
      value = var.api ? aws_ssm_parameter.api_key[0].name : null
    }
   
  }
}
