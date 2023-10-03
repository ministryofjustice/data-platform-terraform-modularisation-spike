variable "environment" {
  description = "The environment name"
  type        = string
}

variable "gateway_id" {
  description = "The ID of the API gateway"
  type        = string
}

variable "parent_resource_id" {
  description = "The parent resource the endpoint will be attached to"
  type        = string
}

variable "authorizor_id" {
  description = "The ID of the custom authorizer for the API"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "region" {
  description = "The AWS account region. Must match the region the gateway_id resource is deployed into"
  type        = string
}

variable "presigned_url_version" {
  description = "The version of the presigned URL lambda docker image"
  type        = string
}

variable "bucket_id" {
  description = "(Landing zone) bucket ID"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}
