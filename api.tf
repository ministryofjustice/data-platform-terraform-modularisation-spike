
module "api_core" {
  source             = "./modules/api_core"
  environment        = local.environment
  tags               = local.tags
  account_id         = local.account_id
  region             = local.region
  authorizer_version = local.authorizer_version
}

module "api_endpoints" {
  source                          = "./modules/api_endpoints"
  environment                     = local.environment
  presigned_url_lambda_invoke_arn = module.presigned_url_lambda.invoke_arn
  gateway_id                      = module.api_core.gateway_id
  root_resource_id                = module.api_core.root_resource_id
  authorizor_id                   = module.api_core.authorizor_id
  account_id                      = local.account_id
  region                          = local.region
}
