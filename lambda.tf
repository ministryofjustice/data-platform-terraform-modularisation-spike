
module "authorizor_lambda" {
  source = "./modules/authorizor_lambda"
  environment = local.environment
  api_resource_arn = aws_api_gateway_rest_api.data_platform.execution_arn
  api_source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/*"
  tags = local.tags
  account_id = local.account_id
  region = local.region
  authorizer_version = local.authorizer_version
}

module "presigned_url_lambda" {
  source = "./modules/presigned_url_lambda"
  tags= local.tags
  environment = local.environment
  presigned_url_version=local.presigned_url_version
  account_id = local.account_id
  region = local.region
  bucket_id=module.s3-bucket.bucket.id
  policy_json=data.aws_iam_policy_document.iam_policy_document_for_presigned_url_lambda.json
  source_arn_value="arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.upload_data_get.http_method}${aws_api_gateway_resource.upload_data.path}"
}
 