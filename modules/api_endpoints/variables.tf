variable "presigned_url_lambda_invoke_arn" {
  description = "The invoke ARN of the presigned URL lambda"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "gateway_id" {
  description = "The ID of the API gateway"
  type        = string
}

variable "root_resource_id" {
  type = string
}

variable "authorizor_id" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}
