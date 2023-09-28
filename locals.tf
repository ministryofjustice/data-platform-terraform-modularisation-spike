#### This file can be used to store locals specific to the member account ####
locals {
  lambda_runtime            = "python3.9"
  lambda_timeout_in_seconds = 15
  region                    = "eu-west-2"
  account_id                = "684969100054"
  environment = "sandbox"
  authorizer_version="1.0.0"
  presigned_url_version= "1.1.0"
  
}