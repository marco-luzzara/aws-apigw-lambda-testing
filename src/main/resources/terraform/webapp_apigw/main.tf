locals {
  request_mapping_template = <<-EOT
    {
      "headers": {
        #foreach($param in $input.params().header.keySet())
          "$param": "$util.escapeJavaScript($input.params().header.get($param))"
          #if($foreach.hasNext),#end
        #end
      },
      "body" : %s
    }
    EOT
}

resource "aws_api_gateway_rest_api" "webapp_rest_api" {
  name = "webapp-api"
}

resource "aws_lambda_permission" "authorizer_lambda_permission" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_lambda_info.function_name
  principal     = "apigateway.amazonaws.com"
  #  source_arn = "${aws_api_gateway_rest_api.webapp_rest_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "admin_lambda_permission" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.admin_lambda_info.function_name
  principal     = "apigateway.amazonaws.com"
  #  source_arn = "${aws_api_gateway_rest_api.webapp_rest_api.execution_arn}/*/*"
}

resource "aws_api_gateway_authorizer" "custom_authorizer" {
  name                   = "custom-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.webapp_rest_api.id
  type                   = "REQUEST"
  authorizer_uri         = var.authorizer_lambda_info.invoke_arn
  identity_source        = "method.request.header.Authorization"
}

# ************************ Customers API ************************

# ********* POST /login
resource "aws_api_gateway_resource" "webapp_login_resource" {
  rest_api_id = aws_api_gateway_rest_api.webapp_rest_api.id
  parent_id   = aws_api_gateway_rest_api.webapp_rest_api.root_resource_id
  path_part   = "login"
}

module "user_login" {
  source = "../webapp_apigw_integration"
  rest_api_id = aws_api_gateway_rest_api.webapp_rest_api.id
  resource_id = aws_api_gateway_resource.webapp_login_resource.id
  http_method = "POST"
  authorization = "NONE"
  authorizer_id = null
  lambda_invocation_arn = var.admin_lambda_info.invoke_arn
  http_successful_status_code = "200"
  request_template_for_body = "$input.json('$')"
  spring_cloud_function_definition_header_value = "loginUser"
}

# ********* GET /users/me
resource "aws_api_gateway_resource" "webapp_users_resource" {
  rest_api_id = aws_api_gateway_rest_api.webapp_rest_api.id
  parent_id   = aws_api_gateway_rest_api.webapp_rest_api.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "webapp_users_me_resource" {
  rest_api_id = aws_api_gateway_rest_api.webapp_rest_api.id
  parent_id   = aws_api_gateway_resource.webapp_users_resource.id
  path_part   = "me"
}

module "get_user" {
  source = "../webapp_apigw_integration"
  rest_api_id = aws_api_gateway_rest_api.webapp_rest_api.id
  resource_id = aws_api_gateway_resource.webapp_users_me_resource.id
  http_method = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id
  lambda_invocation_arn = var.admin_lambda_info.invoke_arn
  http_successful_status_code = "200"
  request_template_for_body = "$input.json('$')"
  spring_cloud_function_definition_header_value = "getUser"
    http_fail_status_codes = [
      {
        status_code = "404"
        selection_pattern = "User with id \\d+ does not exist"
      }
    ]
}