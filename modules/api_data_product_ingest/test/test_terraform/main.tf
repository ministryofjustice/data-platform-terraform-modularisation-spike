// Use the environment to give resources unique names between test runs
variable "environment" {
  type = string
}

variable "bucket_id" {
  type = string
}

module "api_core" {
  source             = "../../../api_core"
  tags               = {}
  account_id         = "684969100054"
  region             = "eu-west-2"
  authorizer_version = "1.0.0"
  environment        = var.environment
}

module "api_data_product_ingest" {
  source                = "../../"
  environment           = var.environment
  tags                  = {}
  gateway_id            = module.api_core.gateway_id
  parent_resource_id    = module.api_core.root_resource_id
  authorizor_id         = module.api_core.authorizor_id
  account_id            = "684969100054"
  region                = "eu-west-2"
  presigned_url_version = "1.0.0"
  bucket_id             = var.bucket_id
}

// Deploy to the "test" stage
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = module.api_core.gateway_id

  triggers = {
    redeployment = sha1(jsonencode(module.api_data_product_ingest.redeployment_triggers))
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
