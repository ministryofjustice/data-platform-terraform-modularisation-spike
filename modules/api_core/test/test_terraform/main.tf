module "api_core" {
  source             = "../../"
  tags               = {}
  account_id         = "684969100054"
  region             = "eu-west-2"
  authorizer_version = "1.0.0"
  environment        = var.environment
}

variable "environment" {
  type = string
}
