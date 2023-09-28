variable "environment" {
  description = "The environment name"
  type        = string
}

variable "bucket_id" {
  description = "Bucket id"
  type        = string
}

variable "account_id" {
  type = string
}

variable "presigned_url_version" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "policy_json" {
  type = string
}
