resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = var.gateway_id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.upload_data,
      aws_api_gateway_method.upload_data_get,
      aws_api_gateway_integration.upload_data_to_lambda
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default_stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = var.gateway_id
  stage_name    = var.environment
}

# # presigned url API endpoint

resource "aws_api_gateway_resource" "upload_data" {
  parent_id   = var.root_resource_id
  path_part   = "upload_data"
  rest_api_id = var.gateway_id
}

resource "aws_api_gateway_method" "upload_data_get" {
  authorization = "CUSTOM"
  authorizer_id = var.authorizor_id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.upload_data.id
  rest_api_id   = var.gateway_id

  request_parameters = {
    "method.request.header.Authorization"   = true
    "method.request.querystring.database"   = true,
    "method.request.querystring.table"      = true,
    "method.request.querystring.contentMD5" = true,
  }
}

resource "aws_api_gateway_integration" "upload_data_to_lambda" {
  http_method             = aws_api_gateway_method.upload_data_get.http_method
  resource_id             = aws_api_gateway_resource.upload_data.id
  rest_api_id             = var.gateway_id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.presigned_url_lambda_invoke_arn

  request_parameters = {
    "integration.request.querystring.database"   = "method.request.querystring.database",
    "integration.request.querystring.table"      = "method.request.querystring.table",
    "integration.request.querystring.contentMD5" = "method.request.querystring.contentMD5"
  }
}

resource "aws_lambda_permission" "trigger_presigned_url_from_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = "data_product_presigned_url_${var.environment}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.account_id}:${var.gateway_id}/*/${aws_api_gateway_method.upload_data_get.http_method}${aws_api_gateway_resource.upload_data.path}"
}
