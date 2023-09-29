module "api_core" {
  source             = "../../"
  tags               = {}
  account_id         = "684969100054"
  region             = "eu-west-2"
  authorizer_version = "1.0.0"
  environment        = var.environment
}

resource "aws_api_gateway_method" "api_get" {
  #authorization = "CUSTOM"
  authorization = "NONE"
  #authorizer_id = module.api_core.authorizor_id
  http_method = "GET"
  resource_id = module.api_core.root_resource_id
  rest_api_id = module.api_core.gateway_id

  # request_parameters = {
  #   "method.request.header.Authorization" = true
  # }
}

resource "aws_api_gateway_integration" "api_get_mock" {
  http_method             = aws_api_gateway_method.api_get.http_method
  resource_id             = module.api_core.root_resource_id
  rest_api_id             = module.api_core.gateway_id
  integration_http_method = "GET"
  type                    = "MOCK"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = module.api_core.gateway_id
  resource_id = module.api_core.root_resource_id
  http_method = aws_api_gateway_method.api_get.http_method
  status_code = "200"
}

variable "environment" {
  type = string
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = module.api_core.gateway_id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode(aws_api_gateway_integration.api_get_mock))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default_stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = module.api_core.gateway_id
  stage_name    = "test"
}
