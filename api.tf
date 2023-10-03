
module "api_core" {
  source             = "./modules/api_core"
  environment        = local.environment
  tags               = local.tags
  account_id         = local.account_id
  region             = local.region
  authorizer_version = local.authorizer_version
}

module "api_data_product_ingest" {
  source                = "./modules/api_data_product_ingest"
  environment           = local.environment
  tags                  = local.tags
  gateway_id            = module.api_core.gateway_id
  parent_resource_id    = module.api_core.root_resource_id
  authorizor_id         = module.api_core.authorizor_id
  account_id            = local.account_id
  region                = local.region
  presigned_url_version = local.presigned_url_version
  bucket_id             = module.s3-bucket.bucket.id
  policy_json           = data.aws_iam_policy_document.iam_policy_document_for_presigned_url_lambda.json
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
    redeployment = sha1(jsonencode(module.api_data_product_ingest.redeployment_triggers))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default_stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = module.api_core.gateway_id
  stage_name    = local.environment
}
