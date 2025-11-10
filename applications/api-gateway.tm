generate_hcl "_auto_generated_api-gateway.tf" {
  condition = tm_anytrue([
    tm_try(global.api, false)
  ])
  content {
    data "aws_lb" "elb" {
      arn  = var.elb.nlb_arn
    }

    resource "aws_api_gateway_rest_api" "api" {
      name        = "${var.app_name}-${var.environment}"
      description = "REST API for ${var.app_name}"
      endpoint_configuration {
        types = ["REGIONAL"]
      }

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = "*"
            Action = "execute-api:Invoke"
            Resource = "*"
          }
        ]
      })
    }

    resource "aws_api_gateway_vpc_link" "vpc_link" {
      name        = "${var.app_name}-${var.environment}-vpc-link"
      target_arns = [var.elb.nlb_arn]
    }

    resource "aws_api_gateway_resource" "parent" {
      rest_api_id = aws_api_gateway_rest_api.api.id
      parent_id   = aws_api_gateway_rest_api.api.root_resource_id
      path_part   = var.api.parent_path
    }

    resource "aws_api_gateway_resource" "children" {
      for_each = toset(var.api.child_paths)

      rest_api_id = aws_api_gateway_rest_api.api.id
      parent_id   = aws_api_gateway_resource.parent.id
      path_part   = each.value
    }



    #resource "aws_api_gateway_resource" "orders" {
    #  rest_api_id = aws_api_gateway_rest_api.api.id
    #  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
    #  path_part   = "orders"
    #}
#
    #resource "aws_api_gateway_resource" "orders_proxy" {
    #  rest_api_id = aws_api_gateway_rest_api.api.id
    #  parent_id   = aws_api_gateway_resource.orders.id
    #  path_part   = "{id}"
    #}

    resource "aws_api_gateway_method" "parent_method" {
      rest_api_id      = aws_api_gateway_rest_api.api.id
      resource_id      = aws_api_gateway_resource.parent.id
      http_method      = "ANY"
      authorization    = "NONE"
      api_key_required = true
    }

    resource "aws_api_gateway_method" "child_methods" {
      for_each = aws_api_gateway_resource.children

      rest_api_id      = aws_api_gateway_rest_api.api.id
      resource_id      = each.value.id
      http_method      = "ANY"
      authorization    = "NONE"
      api_key_required = true

      request_parameters = {
        "method.request.path.id" = true  # enable path parameter
      }
    }



    #resource "aws_api_gateway_method" "orders_method" {
    #  rest_api_id   = aws_api_gateway_rest_api.api.id
    #  resource_id   = aws_api_gateway_resource.orders.id
    #  http_method   = "ANY"
    #  authorization = "NONE"
    #  api_key_required = true
    #}
#
    #resource "aws_api_gateway_method" "orders_proxy_method" {
    #  rest_api_id   = aws_api_gateway_rest_api.api.id
    #  resource_id   = aws_api_gateway_resource.orders_proxy.id
    #  http_method   = "ANY"
    #  authorization = "NONE"
    #  api_key_required = true
#
    #  request_parameters = {
    #    "method.request.path.id" = true
    #  }
    #}


    resource "aws_api_gateway_integration" "parent_integration" {
      rest_api_id             = aws_api_gateway_rest_api.api.id
      resource_id             = aws_api_gateway_resource.parent.id
      http_method             = aws_api_gateway_method.parent_method.http_method
      integration_http_method = "ANY"
      type                    = "HTTP_PROXY"
      connection_type         = "VPC_LINK"
      connection_id           = aws_api_gateway_vpc_link.vpc_link.id
      uri                     = "http://${data.aws_lb.elb.dns_name}/api/${var.api.parent_path}"
    }

    resource "aws_api_gateway_integration" "child_integrations" {
      for_each = aws_api_gateway_resource.children

      rest_api_id             = aws_api_gateway_rest_api.api.id
      resource_id             = each.value.id
      http_method             = aws_api_gateway_method.child_methods[each.key].http_method
      integration_http_method = "ANY"
      type                    = "HTTP_PROXY"
      connection_type         = "VPC_LINK"
      connection_id           = aws_api_gateway_vpc_link.vpc_link.id
      uri                     = "http://${data.aws_lb.elb.dns_name}/api/${var.api.parent_path}/{id}"

      request_parameters = {
        "integration.request.path.id" = "method.request.path.id"
      }
    }


    #resource "aws_api_gateway_integration" "alb_integration_orders" {
    #  rest_api_id             = aws_api_gateway_rest_api.api.id
    #  resource_id             = aws_api_gateway_resource.orders.id
    #  http_method             = aws_api_gateway_method.orders_method.http_method
    #  integration_http_method = "ANY"
    #  type                    = "HTTP_PROXY"
    #  uri                     = "http://${data.aws_lb.elb.dns_name}/api/orders"
    #  connection_type         = "VPC_LINK"
    #  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
    #}
#
    #resource "aws_api_gateway_integration" "alb_integration_orders_proxy" {
    #  rest_api_id             = aws_api_gateway_rest_api.api.id
    #  resource_id             = aws_api_gateway_resource.orders_proxy.id
    #  http_method             = aws_api_gateway_method.orders_proxy_method.http_method
    #  integration_http_method = "ANY"
    #  type                    = "HTTP_PROXY"
    #  uri                     = "http://${data.aws_lb.elb.dns_name}/api/orders/{id}"
    #  connection_type         = "VPC_LINK"
    #  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
#
    #  request_parameters = {
    #    "integration.request.path.id" = "method.request.path.id"
    #  }
    #}
   
    resource "aws_api_gateway_deployment" "deployment" {
      depends_on = [
        aws_api_gateway_integration.parent_integration,
        aws_api_gateway_integration.child_integrations
      ]
      rest_api_id = aws_api_gateway_rest_api.api.id
    }

    resource "aws_api_gateway_stage" "stage" {
      deployment_id = aws_api_gateway_deployment.deployment.id
      rest_api_id   = aws_api_gateway_rest_api.api.id
      stage_name    = var.environment
    }

    resource "random_password" "api_key" {
      length  = 32
      special = false
    }

    resource "aws_ssm_parameter" "api_key" {
      name        = "/app/${var.app_name}/${var.environment}/api_key"
      description = "API Gateway key for ${var.app_name}"
      type        = "SecureString"
      value       = random_password.api_key.result
    }

    resource "aws_api_gateway_api_key" "api_key" {
      name        = "${var.app_name}-${var.environment}-api-key"
      description = "API key for ${var.app_name}"
      enabled     = true
      value       = random_password.api_key.result
    }

    resource "aws_api_gateway_usage_plan" "usage_plan" {
      name = "${var.app_name}-${var.environment}-usage-plan"

      api_stages {
        api_id = aws_api_gateway_rest_api.api.id
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

      depends_on = [aws_api_gateway_stage.stage]
    }

    resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
      key_id        = aws_api_gateway_api_key.api_key.id
      key_type      = "API_KEY"
      usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
    }
   
  }
}
