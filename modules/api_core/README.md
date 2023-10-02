# API core

This module creates a REST API with the custom authorizer.

This is a dependency of all of the API resources and methods.

Usage:

```
module "api_core" {
  source             = "./modules/api_core"
  environment        = local.environment
  tags               = local.tags
  account_id         = local.account_id
  region             = local.region
  authorizer_version = local.authorizer_version
}
```
