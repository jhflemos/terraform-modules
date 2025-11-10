generate_hcl "_auto_generated_api-gateway.tf" {
  condition = tm_anytrue([
    tm_try(global.api, false)
  ])
  content {

    locals {
      # Flatten paths and map each path to its parent
      path_map = { for path in var.api.paths :
        path => {
          parent = length(split("/", path)) == 1 ? aws_api_gateway_rest_api.api.root_resource_id : join("/", slice(split("/", path), 0, -1))
          path_part = split("/", path)[length(split("/", path))-1]
        }
      }
    }

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

    resource "aws_api_gateway_resource" "resources" {
      for_each = local.path_map

      rest_api_id = aws_api_gateway_rest_api.api.id
      parent_id   = each.value.parent == aws_api_gateway_rest_api.api.root_resource_id ? aws_api_gateway_rest_api.api.root_resource_id : aws_api_gateway_resource.resources[each.value.parent].id
      path_part   = each.value.path_part
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

    resource "aws_api_gateway_method" "methods" {
      for_each = aws_api_gateway_resource.resources

      rest_api_id      = aws_api_gateway_rest_api.api.id
      resource_id      = each.value.id
      http_method      = "ANY"
      authorization    = "NONE"
      api_key_required = true

      # Enable path parameter if needed
      request_parameters = { for p in regexall("\\{(.*?)\\}", each.key) : "method.request.path.${p}" => true }
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


    resource "aws_api_gateway_integration" "integrations" {
      for_each = aws_api_gateway_method.methods

      rest_api_id             = aws_api_gateway_rest_api.api.id
      resource_id             = each.value.resource_id
      http_method             = each.value.http_method
      integration_http_method = "ANY"
      type                    = "HTTP_PROXY"
      connection_type         = "VPC_LINK"
      connection_id           = aws_api_gateway_vpc_link.vpc_link.id

      uri = "http://${data.aws_lb.elb.dns_name}/api/${each.key}"

      request_parameters = { for p in regexall("\\{(.*?)\\}", each.key) : "integration.request.path.${p}" => "method.request.path.${p}" }
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
        aws_api_gateway_integration.integrations,
        aws_api_gateway_method.methods
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
