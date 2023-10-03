
output "redeployment_triggers" {
  value = [
    aws_api_gateway_resource.upload_data,
    aws_api_gateway_method.upload_data_get,
    aws_api_gateway_integration.upload_data_to_lambda
  ]
}
