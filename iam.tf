# S3 policy

data "aws_iam_policy_document" "data_platform_product_bucket_policy_document" {
  statement {
    sid    = "AllowPutFromCiUser"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::684969100054:role/data-engineering-infrastructure"]
    }

    actions = ["s3:PutObject", "s3:ListBucket"]

    resources = [module.s3-bucket.bucket.arn, "${module.s3-bucket.bucket.arn}/*"]
  }

  statement {
    sid       = "DenyNonFullControlObjects"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${module.s3-bucket.bucket.arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

}

data "aws_iam_policy_document" "iam_policy_document_for_presigned_url_lambda" {
  statement {
    sid       = "GetPutDataObject"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["*"]
  }
  statement {
    sid       = "ListExistingDataProducts"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["code/*"]
    }

  }
}
