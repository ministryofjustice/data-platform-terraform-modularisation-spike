module "data_product_presigned_url_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=v2.0.1"
  application_name               = "data_product_presigned_url"
  tags                           = var.tags
  description                    = "Lambda to generate a presigned url for uploading data"
  create_role                    = true
  role_name                      = "presigned_url_lambda_role_${var.environment}"
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_presigned_url_lambda.json
  function_name                  = "data_product_presigned_url_${var.environment}"
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-presigned-url-lambda-ecr-repo:1.1.0"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = {
    BUCKET_NAME = var.bucket_id
  }
}
