output "gateway_id" {
  description = "ID of the REST API gateway"
  value       = aws_api_gateway_rest_api.data_platform.id
}

output "root_resource_id" {
  description = "The ID of the root API resource, i.e. '/'. All other resources are nested below this one."
  value       = aws_api_gateway_rest_api.data_platform.root_resource_id
}

output "authorizor_id" {
  description = "The ID of the custom authorizer, which should be used for all non-public endpoints."
  value       = aws_api_gateway_authorizer.authorizer.id
}
